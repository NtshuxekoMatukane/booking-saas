CREATE TABLE businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name TEXT NOT NULL,

    slug TEXT NOT NULL UNIQUE,

    timezone TEXT NOT NULL DEFAULT 'Africa/Johannesburg',

    email CITEXT,

    phone TEXT,

    address TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT businesses_name_not_blank
        CHECK (length(trim(name)) > 0),

    CONSTRAINT businesses_slug_not_blank
        CHECK (length(trim(slug)) > 0),

    CONSTRAINT businesses_timezone_not_blank
        CHECK (length(trim(timezone)) > 0)
);