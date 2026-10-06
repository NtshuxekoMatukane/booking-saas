import "dotenv/config";
import assert from "node:assert/strict";
import { pool } from "../pool.js";
import { getAvailability } from "../../services/availability/availability.service.js";

const TEST_DATE = "2026-10-07";

async function run() {
  let businessId: string | undefined;
  let staffId: string | undefined;
  let serviceId: string | undefined;
  let customerId: string | undefined;

  const client = await pool.connect();

  try {
    console.log("--- Availability integration test starting ---");

    await client.query("BEGIN");

    const businessResult = await client.query<{ id: string }>(
      `
        INSERT INTO businesses (
          name,
          slug,
          timezone
        )
        VALUES (
          'Availability Integration Test',
          'availability-integration-test',
          'Africa/Johannesburg'
        )
        RETURNING id
      `
    );

    businessId = businessResult.rows[0]?.id;

    assert.ok(businessId, "Business was not created.");

    const staffResult = await client.query<{ id: string }>(
      `
        INSERT INTO staff_profiles (
          business_id,
          display_name
        )
        VALUES (
          $1,
          'Integration Test Barber'
        )
        RETURNING id
      `,
      [businessId]
    );

    staffId = staffResult.rows[0]?.id;

    assert.ok(staffId, "Staff was not created.");

    const serviceResult = await client.query<{ id: string }>(
      `
        INSERT INTO services (
          business_id,
          name,
          duration_minutes,
          buffer_minutes,
          price_cents
        )
        VALUES (
          $1,
          'Integration Test Haircut',
          45,
          15,
          15000
        )
        RETURNING id
      `,
      [businessId]
    );

    serviceId = serviceResult.rows[0]?.id;

    assert.ok(serviceId, "Service was not created.");

    await client.query(
      `
        INSERT INTO staff_services (
          business_id,
          staff_id,
          service_id
        )
        VALUES ($1, $2, $3)
      `,
      [businessId, staffId, serviceId]
    );

    await client.query(
      `
        INSERT INTO business_hours (
          business_id,
          day_of_week,
          start_time,
          end_time
        )
        VALUES (
          $1,
          3,
          '09:00',
          '17:00'
        )
      `,
      [businessId]
    );

    await client.query(
      `
        INSERT INTO staff_working_hours (
          business_id,
          staff_id,
          day_of_week,
          start_time,
          end_time
        )
        VALUES (
          $1,
          $2,
          3,
          '09:00',
          '17:00'
        )
      `,
      [businessId, staffId]
    );

    const customerResult = await client.query<{ id: string }>(
      `
        INSERT INTO customers (
          business_id,
          full_name,
          phone
        )
        VALUES (
          $1,
          'Integration Test Customer',
          '+27821123457'
        )
        RETURNING id
      `,
      [businessId]
    );

    customerId = customerResult.rows[0]?.id;

    assert.ok(customerId, "Customer was not created.");

    await client.query(
      `
        INSERT INTO appointments (
          business_id,
          customer_id,
          staff_id,
          service_id,
          start_at,
          end_at,
          blocked_until,
          status,
          service_name_snapshot,
          price_charged_cents,
          duration_minutes_snapshot,
          buffer_minutes_snapshot
        )
        VALUES (
          $1,
          $2,
          $3,
          $4,
          '2026-10-07 10:00:00+02',
          '2026-10-07 10:45:00+02',
          '2026-10-07 11:00:00+02',
          'CONFIRMED',
          'Integration Test Haircut',
          15000,
          45,
          15
        )
      `,
      [
        businessId,
        customerId,
        staffId,
        serviceId,
      ]
    );

    await client.query(
      `
        INSERT INTO time_off (
          business_id,
          staff_id,
          starts_at,
          ends_at,
          reason
        )
        VALUES (
          $1,
          $2,
          '2026-10-07 13:00:00+02',
          '2026-10-07 14:00:00+02',
          'Integration test break'
        )
      `,
      [businessId, staffId]
    );

    await client.query("COMMIT");

    console.log("Test fixture created.");

    const result = await getAvailability({
      businessId,
      staffId,
      serviceId,
      localDate: TEST_DATE,
      slotIntervalMinutes: 15,
    });

    console.log("Returned slots:");
    console.log(result.slots);

    const expectedSlots = [
        "2026-10-07T07:00:00.000Z",

        "2026-10-07T09:00:00.000Z",
        "2026-10-07T09:15:00.000Z",
        "2026-10-07T09:30:00.000Z",
        "2026-10-07T09:45:00.000Z",
        "2026-10-07T10:00:00.000Z",

        "2026-10-07T12:00:00.000Z",
        "2026-10-07T12:15:00.000Z",
        "2026-10-07T12:30:00.000Z",
        "2026-10-07T12:45:00.000Z",
        "2026-10-07T13:00:00.000Z",
        "2026-10-07T13:15:00.000Z",
        "2026-10-07T13:30:00.000Z",
        "2026-10-07T13:45:00.000Z",
        "2026-10-07T14:00:00.000Z",
    ];

    assert.deepEqual(
      result.slots,
      expectedSlots,
      "Availability slots do not match expected results."
    );

    console.log(
      "PASS: Availability slots exactly match expected results."
    );

    assert.equal(
      result.timezone,
      "Africa/Johannesburg"
    );

    console.log(
      "PASS: Business timezone is correct."
    );

    assert.equal(
      result.slotIntervalMinutes,
      15
    );

    console.log(
      "PASS: Slot interval is correct."
    );

    console.log(
      "--- Availability integration test passed ---"
    );
  } catch (error) {
    console.error(
      "--- Availability integration test FAILED ---"
    );
    console.error(error);

    try {
      await client.query("ROLLBACK");
    } catch {
      // Ignore rollback errors.
    }

    process.exitCode = 1;
  } finally {
    await client.query("BEGIN");

    if (businessId) {
      await client.query(
        `
          DELETE FROM businesses
          WHERE id = $1
        `,
        [businessId]
      );
    }

    await client.query("COMMIT");

    client.release();
    await pool.end();
  }
}

run();