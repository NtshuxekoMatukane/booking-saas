BEGIN;

-- ============================================================
-- BOOKING SAAS
-- APPOINTMENT DATABASE INTEGRITY TESTS
-- ============================================================

DO $$
DECLARE
    business_a UUID;
    business_b UUID;

    staff_a UUID;
    staff_a2 UUID;
    staff_b UUID;

    service_a UUID;
    service_b UUID;

    customer_a UUID;
    customer_b UUID;

    appointment_a UUID;
    test_count INTEGER;
BEGIN

    RAISE NOTICE '=============================================';
    RAISE NOTICE 'BOOKING SAAS DATABASE INTEGRITY TESTS';
    RAISE NOTICE '=============================================';


    -- ========================================================
    -- TEST DATA
    -- ========================================================

    INSERT INTO businesses (
        name,
        slug
    )
    VALUES (
        'Test Business A',
        'test-business-a'
    )
    RETURNING id INTO business_a;

    INSERT INTO businesses (
        name,
        slug
    )
    VALUES (
        'Test Business B',
        'test-business-b'
    )
    RETURNING id INTO business_b;


    INSERT INTO staff_profiles (
        business_id,
        display_name
    )
    VALUES (
        business_a,
        'Staff A'
    )
    RETURNING id INTO staff_a;

    INSERT INTO staff_profiles (
        business_id,
        display_name
    )
    VALUES (
        business_a,
        'Staff A2'
    )
    RETURNING id INTO staff_a2;

    INSERT INTO staff_profiles (
        business_id,
        display_name
    )
    VALUES (
        business_b,
        'Staff B'
    )
    RETURNING id INTO staff_b;


    INSERT INTO services (
        business_id,
        name,
        duration_minutes,
        buffer_minutes,
        price_cents
    )
    VALUES (
        business_a,
        'Haircut',
        45,
        15,
        15000
    )
    RETURNING id INTO service_a;

    INSERT INTO services (
        business_id,
        name,
        duration_minutes,
        buffer_minutes,
        price_cents
    )
    VALUES (
        business_b,
        'Tattoo',
        60,
        0,
        50000
    )
    RETURNING id INTO service_b;


    INSERT INTO customers (
        business_id,
        full_name,
        phone
    )
    VALUES (
        business_a,
        'Customer A',
        '+27820000001'
    )
    RETURNING id INTO customer_a;

    INSERT INTO customers (
        business_id,
        full_name,
        phone
    )
    VALUES (
        business_b,
        'Customer B',
        '+27820000002'
    )
    RETURNING id INTO customer_b;


    -- ========================================================
    -- TEST 1
    -- CROSS-TENANT CUSTOMER MUST BE REJECTED
    -- ========================================================

    BEGIN
        INSERT INTO appointments (
            business_id,
            customer_id,
            staff_id,
            service_id,
            start_at,
            end_at,
            blocked_until,
            service_name_snapshot,
            price_charged_cents,
            duration_minutes_snapshot,
            buffer_minutes_snapshot
        )
        VALUES (
            business_a,
            customer_b,
            staff_a,
            service_a,
            '2026-11-01 10:00:00+02',
            '2026-11-01 10:45:00+02',
            '2026-11-01 11:00:00+02',
            'Haircut',
            15000,
            45,
            15
        );

        RAISE EXCEPTION
            'TEST 1 FAILED: Cross-tenant customer was accepted.';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE
                'TEST 1 PASSED: Cross-tenant customer rejected.';
    END;


    -- ========================================================
    -- TEST 2
    -- CROSS-TENANT STAFF MUST BE REJECTED
    -- ========================================================

    BEGIN
        INSERT INTO appointments (
            business_id,
            customer_id,
            staff_id,
            service_id,
            start_at,
            end_at,
            blocked_until,
            service_name_snapshot,
            price_charged_cents,
            duration_minutes_snapshot,
            buffer_minutes_snapshot
        )
        VALUES (
            business_a,
            customer_a,
            staff_b,
            service_a,
            '2026-11-01 10:00:00+02',
            '2026-11-01 10:45:00+02',
            '2026-11-01 11:00:00+02',
            'Haircut',
            15000,
            45,
            15
        );

        RAISE EXCEPTION
            'TEST 2 FAILED: Cross-tenant staff was accepted.';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE
                'TEST 2 PASSED: Cross-tenant staff rejected.';
    END;


    -- ========================================================
    -- TEST 3
    -- CROSS-TENANT SERVICE MUST BE REJECTED
    -- ========================================================

    BEGIN
        INSERT INTO appointments (
            business_id,
            customer_id,
            staff_id,
            service_id,
            start_at,
            end_at,
            blocked_until,
            service_name_snapshot,
            price_charged_cents,
            duration_minutes_snapshot,
            buffer_minutes_snapshot
        )
        VALUES (
            business_a,
            customer_a,
            staff_a,
            service_b,
            '2026-11-01 10:00:00+02',
            '2026-11-01 10:45:00+02',
            '2026-11-01 11:00:00+02',
            'Haircut',
            15000,
            45,
            15
        );

        RAISE EXCEPTION
            'TEST 3 FAILED: Cross-tenant service was accepted.';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE
                'TEST 3 PASSED: Cross-tenant service rejected.';
    END;


    -- ========================================================
    -- TEST 4
    -- VALID APPOINTMENT MUST SUCCEED
    -- ========================================================

    INSERT INTO appointments (
        business_id,
        customer_id,
        staff_id,
        service_id,
        start_at,
        end_at,
        blocked_until,
        service_name_snapshot,
        price_charged_cents,
        duration_minutes_snapshot,
        buffer_minutes_snapshot
    )
    VALUES (
        business_a,
        customer_a,
        staff_a,
        service_a,
        '2026-11-01 10:00:00+02',
        '2026-11-01 10:45:00+02',
        '2026-11-01 11:00:00+02',
        'Haircut',
        15000,
        45,
        15
    )
    RETURNING id INTO appointment_a;

    RAISE NOTICE
        'TEST 4 PASSED: Valid appointment created.';


    -- ========================================================
    -- TEST 5
    -- SAME STAFF OVERLAP MUST BE REJECTED
    -- ========================================================

    BEGIN
        INSERT INTO appointments (
            business_id,
            customer_id,
            staff_id,
            service_id,
            start_at,
            end_at,
            blocked_until,
            service_name_snapshot,
            price_charged_cents,
            duration_minutes_snapshot,
            buffer_minutes_snapshot
        )
        VALUES (
            business_a,
            customer_a,
            staff_a,
            service_a,
            '2026-11-01 10:30:00+02',
            '2026-11-01 11:15:00+02',
            '2026-11-01 11:30:00+02',
            'Haircut',
            15000,
            45,
            15
        );

        RAISE EXCEPTION
            'TEST 5 FAILED: Same-staff overlap was accepted.';
    EXCEPTION
        WHEN exclusion_violation THEN
            RAISE NOTICE
                'TEST 5 PASSED: Same-staff overlap rejected.';
    END;


    -- ========================================================
    -- TEST 6
    -- DIFFERENT STAFF MAY OVERLAP
    -- ========================================================

    INSERT INTO appointments (
        business_id,
        customer_id,
        staff_id,
        service_id,
        start_at,
        end_at,
        blocked_until,
        service_name_snapshot,
        price_charged_cents,
        duration_minutes_snapshot,
        buffer_minutes_snapshot
    )
    VALUES (
        business_a,
        customer_a,
        staff_a2,
        service_a,
        '2026-11-01 10:30:00+02',
        '2026-11-01 11:15:00+02',
        '2026-11-01 11:30:00+02',
        'Haircut',
        15000,
        45,
        15
    );

    RAISE NOTICE
        'TEST 6 PASSED: Different staff can have overlapping appointments.';


    -- ========================================================
    -- TEST 7
    -- CANCELLED APPOINTMENT MUST NOT BLOCK
    -- ========================================================

    UPDATE appointments
    SET status = 'CANCELLED'
    WHERE id = appointment_a;

    INSERT INTO appointments (
        business_id,
        customer_id,
        staff_id,
        service_id,
        start_at,
        end_at,
        blocked_until,
        service_name_snapshot,
        price_charged_cents,
        duration_minutes_snapshot,
        buffer_minutes_snapshot
    )
    VALUES (
        business_a,
        customer_a,
        staff_a,
        service_a,
        '2026-11-01 10:00:00+02',
        '2026-11-01 10:45:00+02',
        '2026-11-01 11:00:00+02',
        'Haircut',
        15000,
        45,
        15
    );

    RAISE NOTICE
        'TEST 7 PASSED: Cancelled appointment no longer blocks the slot.';


    -- ========================================================
    -- TEST 8
    -- BUFFER MUST BLOCK 10:50
    -- ========================================================

    BEGIN
        INSERT INTO appointments (
            business_id,
            customer_id,
            staff_id,
            service_id,
            start_at,
            end_at,
            blocked_until,
            service_name_snapshot,
            price_charged_cents,
            duration_minutes_snapshot,
            buffer_minutes_snapshot
        )
        VALUES (
            business_a,
            customer_a,
            staff_a,
            service_a,
            '2026-11-01 10:50:00+02',
            '2026-11-01 11:35:00+02',
            '2026-11-01 11:50:00+02',
            'Haircut',
            15000,
            45,
            15
        );

        RAISE EXCEPTION
            'TEST 8 FAILED: Appointment entered buffer period.';
    EXCEPTION
        WHEN exclusion_violation THEN
            RAISE NOTICE
                'TEST 8 PASSED: Buffer correctly blocked 10:50.';
    END;


    -- ========================================================
    -- TEST 9
    -- 11:00 SHOULD BE AVAILABLE
    -- ========================================================

    INSERT INTO appointments (
        business_id,
        customer_id,
        staff_id,
        service_id,
        start_at,
        end_at,
        blocked_until,
        service_name_snapshot,
        price_charged_cents,
        duration_minutes_snapshot,
        buffer_minutes_snapshot
    )
    VALUES (
        business_a,
        customer_a,
        staff_a,
        service_a,
        '2026-11-01 11:00:00+02',
        '2026-11-01 11:45:00+02',
        '2026-11-01 12:00:00+02',
        'Haircut',
        15000,
        45,
        15
    );

    RAISE NOTICE
        'TEST 9 PASSED: 11:00 appointment allowed after buffer.';


    -- ========================================================
    -- TEST 10
    -- SNAPSHOT MUST SURVIVE SERVICE CHANGE
    -- ========================================================

    UPDATE services
    SET
        name = 'Premium Haircut',
        price_cents = 20000,
        duration_minutes = 60,
        buffer_minutes = 30
    WHERE id = service_a;

    SELECT COUNT(*)
    INTO test_count
    FROM appointments
    WHERE id = appointment_a
      AND service_name_snapshot = 'Haircut'
      AND price_charged_cents = 15000
      AND duration_minutes_snapshot = 45
      AND buffer_minutes_snapshot = 15;

    IF test_count = 1 THEN
        RAISE NOTICE
            'TEST 10 PASSED: Appointment history retained original service snapshot.';
    ELSE
        RAISE EXCEPTION
            'TEST 10 FAILED: Appointment snapshot changed unexpectedly.';
    END IF;


    -- ========================================================
    -- FINAL RESULT
    -- ========================================================

    RAISE NOTICE '=============================================';
    RAISE NOTICE 'ALL APPOINTMENT INTEGRITY TESTS PASSED';
    RAISE NOTICE '=============================================';

END $$;

-- IMPORTANT:
-- All test records are temporary because we roll back
-- the entire transaction after the test suite finishes.

ROLLBACK;