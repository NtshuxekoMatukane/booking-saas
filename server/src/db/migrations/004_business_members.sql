CREATE TABLE business_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    business_id UUID NOT NULL,

    user_id UUID NOT NULL,

    role TEXT NOT NULL DEFAULT 'STAFF',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT business_members_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT business_members_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT business_members_role_check
        CHECK (role IN ('OWNER', 'ADMIN', 'STAFF')),

    CONSTRAINT business_members_business_user_unique
        UNIQUE (business_id, user_id)
);

CREATE INDEX business_members_business_role_idx
    ON business_members (business_id, role);