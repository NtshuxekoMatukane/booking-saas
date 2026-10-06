CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    business_id UUID NOT NULL,

    name TEXT NOT NULL,

    description TEXT,

    duration_minutes INTEGER NOT NULL,

    buffer_minutes INTEGER NOT NULL DEFAULT 0,

    price_cents INTEGER NOT NULL DEFAULT 0,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT services_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT services_name_not_blank
        CHECK (length(trim(name)) > 0),

    CONSTRAINT services_duration_positive
        CHECK (duration_minutes > 0),

    CONSTRAINT services_buffer_non_negative
        CHECK (buffer_minutes >= 0),

    CONSTRAINT services_price_non_negative
        CHECK (price_cents >= 0)
);

CREATE INDEX services_business_active_idx
    ON services (business_id, is_active);