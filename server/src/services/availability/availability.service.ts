import { withTenantTransaction } from "../../db/withTenantTransaction.js";

import {
  filterCandidatesAgainstBlocks,
  generateCandidates,
  intersectWindowSets,
  subtractBlockedIntervals,
} from "./availability.utils.js";

import type {
  AvailabilityBlock,
  AvailabilityRequest,
  AvailabilityResult,
  AvailabilityWindow,
} from "./availability.types.js";

interface BusinessRow {
  timezone: string;
}

interface ServiceRow {
  duration_minutes: number;
  buffer_minutes: number;
}

interface IntervalRow {
  start_at: Date;
  end_at: Date;
}

interface BlockRow {
  start_at: Date;
  end_at: Date;
  block_type: "APPOINTMENT" | "TIME_OFF";
}

const DEFAULT_SLOT_INTERVAL_MINUTES = 15;

export async function getAvailability(
  request: AvailabilityRequest
): Promise<AvailabilityResult> {
  const slotIntervalMinutes =
    request.slotIntervalMinutes ??
    DEFAULT_SLOT_INTERVAL_MINUTES;

  if (
    !/^\d{4}-\d{2}-\d{2}$/.test(
      request.localDate
    )
  ) {
    throw new Error(
      "localDate must use YYYY-MM-DD format."
    );
  }

  return withTenantTransaction(
    request.businessId,
    async (client) => {
      /*
       * ---------------------------------------------------------
       * 1. Load the business timezone.
       * ---------------------------------------------------------
       */

      const businessResult =
        await client.query<BusinessRow>(
          `
            SELECT timezone
            FROM businesses
            WHERE id = $1
              AND is_active = TRUE
          `,
          [request.businessId]
        );

      if (businessResult.rowCount === 0) {
        throw new Error(
          "Business not found or inactive."
        );
      }

      const business = businessResult.rows[0];

      if (!business) {
        throw new Error("Business could not be loaded.");
      }

      const { timezone } = business;

      /*
       * ---------------------------------------------------------
       * 2. Load the service and verify that this staff member
       *    is allowed to perform it.
       * ---------------------------------------------------------
       */

      const serviceResult =
        await client.query<ServiceRow>(
          `
            SELECT
              s.duration_minutes,
              s.buffer_minutes
            FROM services s
            INNER JOIN staff_services ss
              ON ss.business_id = s.business_id
             AND ss.service_id = s.id
             AND ss.staff_id = $3
            INNER JOIN staff_profiles sp
              ON sp.business_id = ss.business_id
             AND sp.id = ss.staff_id
            WHERE s.business_id = $1
              AND s.id = $2
              AND s.is_active = TRUE
              AND sp.is_active = TRUE
          `,
          [
            request.businessId,
            request.serviceId,
            request.staffId,
          ]
        );

      if (serviceResult.rowCount === 0) {
        throw new Error(
          "Service is not available for this staff member."
        );
      }

      const service = serviceResult.rows[0];

      if (!service) {
        throw new Error("Service could not be loaded.");
      }

      const {
        duration_minutes: serviceDurationMinutes,
        buffer_minutes: bufferMinutes,
      } = service;

      /*
       * ---------------------------------------------------------
       * 3. Load business hours for the requested local date.
       *
       * PostgreSQL performs the timezone conversion so the
       * engine works with arbitrary IANA business timezones.
       * ---------------------------------------------------------
       */

      const businessHoursResult =
        await client.query<IntervalRow>(
          `
            SELECT
              (
                ($2::date + start_time)
                AT TIME ZONE $1
              ) AS start_at,

              (
                ($2::date + end_time)
                AT TIME ZONE $1
              ) AS end_at

            FROM business_hours

            WHERE business_id = $3
              AND day_of_week =
                EXTRACT(
                  ISODOW FROM $2::date
                )::SMALLINT

            ORDER BY start_time
          `,
          [
            timezone,
            request.localDate,
            request.businessId,
          ]
        );

      /*
       * ---------------------------------------------------------
       * 4. Load this staff member's working hours.
       * ---------------------------------------------------------
       */

      const staffHoursResult =
        await client.query<IntervalRow>(
          `
            SELECT
              (
                ($2::date + start_time)
                AT TIME ZONE $1
              ) AS start_at,

              (
                ($2::date + end_time)
                AT TIME ZONE $1
              ) AS end_at

            FROM staff_working_hours

            WHERE business_id = $3
              AND staff_id = $4
              AND day_of_week =
                EXTRACT(
                  ISODOW FROM $2::date
                )::SMALLINT

            ORDER BY start_time
          `,
          [
            timezone,
            request.localDate,
            request.businessId,
            request.staffId,
          ]
        );

      /*
       * No business hours or no staff hours means there is
       * nothing bookable.
       */

      if (
        businessHoursResult.rowCount === 0 ||
        staffHoursResult.rowCount === 0
      ) {
        return {
          businessId: request.businessId,
          staffId: request.staffId,
          serviceId: request.serviceId,
          localDate: request.localDate,
          timezone,
          slotIntervalMinutes,
          slots: [],
        };
      }

      const businessWindows: AvailabilityWindow[] =
        businessHoursResult.rows.map((row) => ({
          start: row.start_at,
          end: row.end_at,
        }));

      const staffWindows: AvailabilityWindow[] =
        staffHoursResult.rows.map((row) => ({
          start: row.start_at,
          end: row.end_at,
        }));

      /*
       * ---------------------------------------------------------
       * 5. Intersect business hours with staff hours.
       * ---------------------------------------------------------
       */

      const workingWindows =
        intersectWindowSets(
          businessWindows,
          staffWindows
        );

      if (workingWindows.length === 0) {
        return {
          businessId: request.businessId,
          staffId: request.staffId,
          serviceId: request.serviceId,
          localDate: request.localDate,
          timezone,
          slotIntervalMinutes,
          slots: [],
        };
      }

      /*
       * ---------------------------------------------------------
       * 6. Calculate the UTC boundaries of the requested
       *    business-local calendar day.
       * ---------------------------------------------------------
       */

      const dayBoundaryResult =
        await client.query<{
          day_start: Date;
          day_end: Date;
        }>(
          `
            SELECT
              (
                $2::date
                AT TIME ZONE $1
              ) AS day_start,

              (
                ($2::date + 1)
                AT TIME ZONE $1
              ) AS day_end
          `,
          [
            timezone,
            request.localDate,
          ]
        );

      const dayBoundary = dayBoundaryResult.rows[0];

      if (!dayBoundary) {
        throw new Error(
          "Could not determine the requested day boundaries."
        );
      }

      const {
        day_start: dayStart,
        day_end: dayEnd,
      } = dayBoundary;

      /*
       * ---------------------------------------------------------
       * 7. Unified blocked-space query.
       *
       * One database query retrieves:
       *
       *   - business-wide time off
       *   - staff-specific time off
       *   - active appointment blocks
       *
       * Appointment blocks already include buffer time through
       * appointments.blocked_until.
       * ---------------------------------------------------------
       */

      const blockedResult =
        await client.query<BlockRow>(
          `
            SELECT
              starts_at AS start_at,
              ends_at AS end_at,
              'TIME_OFF'::text AS block_type
            FROM time_off
            WHERE business_id = $1
              AND starts_at < $3
              AND ends_at > $2
              AND (
                staff_id IS NULL
                OR staff_id = $4
              )

            UNION ALL

            SELECT
              start_at,
              blocked_until AS end_at,
              'APPOINTMENT'::text AS block_type
            FROM appointments
            WHERE business_id = $1
              AND staff_id = $4
              AND status <> 'CANCELLED'
              AND start_at < $3
              AND blocked_until > $2

            ORDER BY start_at
          `,
          [
            request.businessId,
            dayStart,
            dayEnd,
            request.staffId,
          ]
        );

      const blocks: AvailabilityBlock[] =
        blockedResult.rows.map((row) => ({
          start: row.start_at,
          end: row.end_at,
          type: row.block_type,
        }));

      /*
       * ---------------------------------------------------------
       * 8. Subtract all blocked space from the working windows.
       * ---------------------------------------------------------
       */

      const freeWindows =
        subtractBlockedIntervals(
          workingWindows,
          blocks
        );

      /*
       * ---------------------------------------------------------
       * 9. Generate the candidate matrix.
       *
       * A candidate must fit the COMPLETE service +
       * buffer period inside a free window.
       * ---------------------------------------------------------
       */

      const candidates = generateCandidates(
        freeWindows,
        serviceDurationMinutes,
        bufferMinutes,
        slotIntervalMinutes
      );

      /*
       * ---------------------------------------------------------
       * 10. Final defensive block check.
       *
       * This makes the engine resilient even if windows/blocks
       * are changed or extended later.
       * ---------------------------------------------------------
       */

      const availableCandidates =
        filterCandidatesAgainstBlocks(
          candidates,
          blocks
        );

      /*
       * ---------------------------------------------------------
       * 11. Do not return starts in the past.
       * ---------------------------------------------------------
       */

      const now = new Date();

      const slots = availableCandidates
        .filter(
          (candidate) =>
            candidate.serviceStart > now
        )
        .map(
          (candidate) =>
            candidate.serviceStart.toISOString()
        );

      return {
        businessId: request.businessId,
        staffId: request.staffId,
        serviceId: request.serviceId,
        localDate: request.localDate,
        timezone,
        slotIntervalMinutes,
        slots,
      };
    }
  );
}