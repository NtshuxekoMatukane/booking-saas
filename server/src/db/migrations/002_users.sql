CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    email CITEXT NOT NULL UNIQUE,

    password_hash TEXT NOT NULL,

    full_name TEXT NOT NULL,

    email_verified_at TIMESTAMPTZ,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT users_full_name_not_blank
        CHECK (length(trim(full_name)) > 0)
);