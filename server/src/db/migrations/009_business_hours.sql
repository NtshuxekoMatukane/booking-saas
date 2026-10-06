CREATE TABLE business_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    business_id UUID NOT NULL,

    day_of_week SMALLINT NOT NULL,

    start_time TIME NOT NULL,

    end_time TIME NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT business_hours_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT business_hours_day_check
        CHECK (day_of_week BETWEEN 1 AND 7),

    CONSTRAINT business_hours_time_check
        CHECK (end_time > start_time)
);

CREATE INDEX business_hours_business_day_start_idx
    ON business_hours (business_id, day_of_week, start_time);

ALTER TABLE business_hours
    ADD CONSTRAINT business_hours_no_overlap
    EXCLUDE USING gist (
        business_id WITH =,
        day_of_week WITH =,
        tsrange(
            TIMESTAMP '2000-01-01' + start_time,
            TIMESTAMP '2000-01-01' + end_time,
            '[)'
        ) WITH &&
    );