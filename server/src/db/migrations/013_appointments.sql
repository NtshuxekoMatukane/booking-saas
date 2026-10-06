CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    business_id UUID NOT NULL,
    customer_id UUID NOT NULL,
    staff_id UUID NOT NULL,
    service_id UUID NOT NULL,

    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    blocked_until TIMESTAMPTZ NOT NULL,

    appointment_block TSTZRANGE GENERATED ALWAYS AS (
        tstzrange(start_at, blocked_until, '[)')
    ) STORED,

    status TEXT NOT NULL DEFAULT 'PENDING',

    service_name_snapshot TEXT NOT NULL,
    price_charged_cents INTEGER NOT NULL,
    duration_minutes_snapshot INTEGER NOT NULL,
    buffer_minutes_snapshot INTEGER NOT NULL,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT appointments_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT appointments_customer_business_fk
        FOREIGN KEY (business_id, customer_id)
        REFERENCES customers (business_id, id)
        ON DELETE RESTRICT,

    CONSTRAINT appointments_staff_business_fk
        FOREIGN KEY (business_id, staff_id)
        REFERENCES staff_profiles (business_id, id)
        ON DELETE RESTRICT,

    CONSTRAINT appointments_service_business_fk
        FOREIGN KEY (business_id, service_id)
        REFERENCES services (business_id, id)
        ON DELETE RESTRICT,

    CONSTRAINT appointments_status_check
        CHECK (
            status IN (
                'PENDING',
                'CONFIRMED',
                'COMPLETED',
                'CANCELLED',
                'NO_SHOW'
            )
        ),

    CONSTRAINT appointments_time_check
        CHECK (end_at > start_at),

    CONSTRAINT appointments_blocked_until_check
        CHECK (blocked_until >= end_at),

    CONSTRAINT appointments_service_name_not_blank
        CHECK (length(trim(service_name_snapshot)) > 0),

    CONSTRAINT appointments_price_non_negative
        CHECK (price_charged_cents >= 0),

    CONSTRAINT appointments_duration_positive
        CHECK (duration_minutes_snapshot > 0),

    CONSTRAINT appointments_buffer_non_negative
        CHECK (buffer_minutes_snapshot >= 0),

    CONSTRAINT appointments_duration_matches_time
        CHECK (
            end_at = start_at
                + make_interval(mins => duration_minutes_snapshot)
        ),

    CONSTRAINT appointments_buffer_matches_time
        CHECK (
            blocked_until = end_at
                + make_interval(mins => buffer_minutes_snapshot)
        )
);

CREATE INDEX appointments_business_start_idx
    ON appointments (business_id, start_at);

CREATE INDEX appointments_business_staff_start_idx
    ON appointments (business_id, staff_id, start_at);

CREATE INDEX appointments_business_customer_start_idx
    ON appointments (business_id, customer_id, start_at);

ALTER TABLE appointments
    ADD CONSTRAINT appointments_no_staff_overlap
    EXCLUDE USING gist (
        business_id WITH =,
        staff_id WITH =,
        appointment_block WITH &&
    )
    WHERE (status <> 'CANCELLED');