CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    business_id UUID NOT NULL,

    full_name TEXT NOT NULL,

    email CITEXT,

    phone TEXT,

    notes TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT customers_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT customers_full_name_not_blank
        CHECK (length(trim(full_name)) > 0),

    CONSTRAINT customers_phone_format
        CHECK (
            phone IS NULL
            OR phone ~ '^\+[1-9][0-9]{7,14}$'
        )
);

CREATE INDEX customers_business_phone_idx
    ON customers (business_id, phone)
    WHERE phone IS NOT NULL;

CREATE INDEX customers_business_active_idx
    ON customers (business_id, is_active);