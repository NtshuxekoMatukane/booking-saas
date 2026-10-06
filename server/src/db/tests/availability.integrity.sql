BEGIN;

DO $$
DECLARE
    test_business UUID;
    test_staff UUID;
    test_service UUID;
    test_customer UUID;

    first_appointment UUID;
BEGIN

    RAISE NOTICE '--- Availability integrity tests starting ---';

    /*
     * ---------------------------------------------------------
     * Create test tenant
     * ---------------------------------------------------------
     */

    INSERT INTO businesses (
        name,
        slug,
        timezone
    )
    VALUES (
        'Availability Test Business',
        'availability-test-business',
        'Africa/Johannesburg'
    )
    RETURNING id INTO test_business;


    /*
     * ---------------------------------------------------------
     * Create staff
     * ---------------------------------------------------------
     */

    INSERT INTO staff_profiles (
        business_id,
        display_name
    )
    VALUES (
        test_business,
        'Availability Test Barber'
    )
    RETURNING id INTO test_staff;


    /*
     * ---------------------------------------------------------
     * Create service
     *
     * 45 minute service
     * 15 minute cleanup buffer
     * ---------------------------------------------------------
     */

    INSERT INTO services (
        business_id,
        name,
        duration_minutes,
        buffer_minutes,
        price_cents
    )
    VALUES (
        test_business,
        'Availability Test Haircut',
        45,
        15,
        15000
    )
    RETURNING id INTO test_service;


    /*
     * ---------------------------------------------------------
     * Link staff to service
     * ---------------------------------------------------------
     */

    INSERT INTO staff_services (
        business_id,
        staff_id,
        service_id
    )
    VALUES (
        test_business,
        test_staff,
        test_service
    );


    /*
     * ---------------------------------------------------------
     * Business hours
     *
     * Wednesday
     * 09:00 - 17:00
     *
     * 2026-10-07 is Wednesday.
     * ---------------------------------------------------------
     */

    INSERT INTO business_hours (
        business_id,
        day_of_week,
        start_time,
        end_time
    )
    VALUES (
        test_business,
        3,
        '09:00',
        '17:00'
    );


    /*
     * ---------------------------------------------------------
     * Staff working hours
     *
     * Wednesday
     * 09:00 - 17:00
     * ---------------------------------------------------------
     */

    INSERT INTO staff_working_hours (
        business_id,
        staff_id,
        day_of_week,
        start_time,
        end_time
    )
    VALUES (
        test_business,
        test_staff,
        3,
        '09:00',
        '17:00'
    );


    /*
     * ---------------------------------------------------------
     * Customer
     * ---------------------------------------------------------
     */

    INSERT INTO customers (
        business_id,
        full_name,
        phone
    )
    VALUES (
        test_business,
        'Availability Test Customer',
        '+27821123456'
    )
    RETURNING id INTO test_customer;


    /*
     * ---------------------------------------------------------
     * Appointment
     *
     * Service:
     * 10:00 - 10:45
     *
     * Buffer:
     * 10:45 - 11:00
     *
     * Therefore blocked:
     * 10:00 - 11:00
     * ---------------------------------------------------------
     */

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
        test_business,
        test_customer,
        test_staff,
        test_service,

        '2026-10-07 10:00:00+02',
        '2026-10-07 10:45:00+02',
        '2026-10-07 11:00:00+02',

        'CONFIRMED',

        'Availability Test Haircut',
        15000,
        45,
        15
    )
    RETURNING id INTO first_appointment;


    /*
     * ---------------------------------------------------------
     * Staff time off
     *
     * 13:00 - 14:00
     * ---------------------------------------------------------
     */

    INSERT INTO time_off (
        business_id,
        staff_id,
        starts_at,
        ends_at,
        reason
    )
    VALUES (
        test_business,
        test_staff,
        '2026-10-07 13:00:00+02',
        '2026-10-07 14:00:00+02',
        'Availability test break'
    );


    RAISE NOTICE 'Test data created successfully.';
    RAISE NOTICE 'Business: %', test_business;
    RAISE NOTICE 'Staff: %', test_staff;
    RAISE NOTICE 'Service: %', test_service;
    RAISE NOTICE 'Appointment: %', first_appointment;


    /*
     * ---------------------------------------------------------
     * Verify appointment block
     * ---------------------------------------------------------
     */

    IF NOT EXISTS (
        SELECT 1
        FROM appointments
        WHERE id = first_appointment
          AND appointment_block @>
              '2026-10-07 10:50:00+02'::timestamptz
    ) THEN
        RAISE EXCEPTION
            'FAIL: Appointment buffer does not block 10:50.';
    END IF;

    RAISE NOTICE
        'PASS: Appointment buffer blocks 10:50.';


    /*
     * ---------------------------------------------------------
     * Verify 11:00 is free from the appointment block
     * ---------------------------------------------------------
     */

    IF EXISTS (
        SELECT 1
        FROM appointments
        WHERE id = first_appointment
          AND appointment_block &&
              tstzrange(
                  '2026-10-07 11:00:00+02'::timestamptz,
                  '2026-10-07 12:00:00+02'::timestamptz,
                  '[)'
              )
    ) THEN
        RAISE EXCEPTION
            'FAIL: 11:00 incorrectly overlaps appointment block.';
    END IF;

    RAISE NOTICE
        'PASS: 11:00 is clear of appointment block.';


    /*
     * ---------------------------------------------------------
     * Verify staff time off
     * ---------------------------------------------------------
     */

    IF NOT EXISTS (
        SELECT 1
        FROM time_off
        WHERE business_id = test_business
          AND staff_id = test_staff
          AND tstzrange(
                starts_at,
                ends_at,
                '[)'
              ) &&
              tstzrange(
                '2026-10-07 13:30:00+02'::timestamptz,
                '2026-10-07 14:00:00+02'::timestamptz,
                '[)'
              )
    ) THEN
        RAISE EXCEPTION
            'FAIL: Staff time-off block was not detected.';
    END IF;

    RAISE NOTICE
        'PASS: Staff time-off block detected.';


    RAISE NOTICE
        '--- Availability database tests passed ---';

END $$;

ROLLBACK;