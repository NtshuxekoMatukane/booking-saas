-- ============================================================
-- 014_tenant_rls.sql
-- Row-Level Security for tenant-owned tables
-- ============================================================

-- ------------------------------------------------------------
-- ENABLE RLS
-- ------------------------------------------------------------

ALTER TABLE business_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_working_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_off ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;


-- ------------------------------------------------------------
-- FORCE RLS
--
-- This ensures the table owner is subject to RLS policies too.
-- PostgreSQL superusers can still bypass RLS.
-- ------------------------------------------------------------

ALTER TABLE business_members FORCE ROW LEVEL SECURITY;
ALTER TABLE services FORCE ROW LEVEL SECURITY;
ALTER TABLE staff_profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE staff_services FORCE ROW LEVEL SECURITY;
ALTER TABLE customers FORCE ROW LEVEL SECURITY;
ALTER TABLE business_hours FORCE ROW LEVEL SECURITY;
ALTER TABLE staff_working_hours FORCE ROW LEVEL SECURITY;
ALTER TABLE time_off FORCE ROW LEVEL SECURITY;
ALTER TABLE appointments FORCE ROW LEVEL SECURITY;


-- ------------------------------------------------------------
-- BUSINESS MEMBERS
-- ------------------------------------------------------------

CREATE POLICY business_members_tenant_isolation
ON business_members
USING (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
)
WITH CHECK (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
);


-- ------------------------------------------------------------
-- SERVICES
-- ------------------------------------------------------------

CREATE POLICY services_tenant_isolation
ON services
USING (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
)
WITH CHECK (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
);


-- ------------------------------------------------------------
-- STAFF PROFILES
-- ------------------------------------------------------------

CREATE POLICY staff_profiles_tenant_isolation
ON staff_profiles
USING (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
)
WITH CHECK (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
);


-- ------------------------------------------------------------
-- STAFF SERVICES
-- ------------------------------------------------------------

CREATE POLICY staff_services_tenant_isolation
ON staff_services
USING (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
)
WITH CHECK (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
);


-- ------------------------------------------------------------
-- CUSTOMERS
-- ------------------------------------------------------------

CREATE POLICY customers_tenant_isolation
ON customers
USING (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
)
WITH CHECK (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
);


-- ------------------------------------------------------------
-- BUSINESS HOURS
-- ------------------------------------------------------------

CREATE POLICY business_hours_tenant_isolation
ON business_hours
USING (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
)
WITH CHECK (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
);


-- ------------------------------------------------------------
-- STAFF WORKING HOURS
-- ------------------------------------------------------------

CREATE POLICY staff_working_hours_tenant_isolation
ON staff_working_hours
USING (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
)
WITH CHECK (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
);


-- ------------------------------------------------------------
-- TIME OFF
-- ------------------------------------------------------------

CREATE POLICY time_off_tenant_isolation
ON time_off
USING (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
)
WITH CHECK (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
);


-- ------------------------------------------------------------
-- APPOINTMENTS
-- ------------------------------------------------------------

CREATE POLICY appointments_tenant_isolation
ON appointments
USING (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
)
WITH CHECK (
    business_id = NULLIF(
        current_setting('app.current_tenant_id', true),
        ''
    )::UUID
);