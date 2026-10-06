CREATE TABLE staff_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    business_id UUID NOT NULL,

    display_name TEXT NOT NULL,

    bio TEXT,

    avatar_url TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT staff_profiles_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT staff_profiles_display_name_not_blank
        CHECK (length(trim(display_name)) > 0)
);

CREATE INDEX staff_profiles_business_active_idx
    ON staff_profiles (business_id, is_active);