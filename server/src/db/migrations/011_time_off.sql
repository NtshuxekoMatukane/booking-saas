CREATE TABLE time_off (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL,
    staff_id UUID,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    time_off_range TSTZRANGE GENERATED ALWAYS AS (
        tstzrange(starts_at, ends_at, '[)')
    ) STORED,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT time_off_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT time_off_staff_fk
        FOREIGN KEY (staff_id)
        REFERENCES staff_profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT time_off_time_check
        CHECK (ends_at > starts_at),

    CONSTRAINT time_off_reason_not_blank
        CHECK (
            reason IS NULL
            OR length(trim(reason)) > 0
        )
);

CREATE INDEX time_off_business_start_idx
    ON time_off (business_id, starts_at);

CREATE INDEX time_off_business_staff_start_idx
    ON time_off (business_id, staff_id, starts_at);