-- Add tenant-aware unique keys to business-owned tables.
ALTER TABLE services
    ADD CONSTRAINT services_business_id_id_unique
    UNIQUE (business_id, id);

ALTER TABLE staff_profiles
    ADD CONSTRAINT staff_profiles_business_id_id_unique
    UNIQUE (business_id, id);

ALTER TABLE customers
    ADD CONSTRAINT customers_business_id_id_unique
    UNIQUE (business_id, id);


-- Replace staff_services foreign keys with tenant-aware foreign keys.
ALTER TABLE staff_services
    DROP CONSTRAINT staff_services_staff_fk,
    DROP CONSTRAINT staff_services_service_fk;

ALTER TABLE staff_services
    ADD CONSTRAINT staff_services_staff_business_fk
        FOREIGN KEY (business_id, staff_id)
        REFERENCES staff_profiles (business_id, id)
        ON DELETE CASCADE,

    ADD CONSTRAINT staff_services_service_business_fk
        FOREIGN KEY (business_id, service_id)
        REFERENCES services (business_id, id)
        ON DELETE CASCADE;


-- Replace staff_working_hours staff relationship.
ALTER TABLE staff_working_hours
    DROP CONSTRAINT staff_working_hours_staff_fk;

ALTER TABLE staff_working_hours
    ADD CONSTRAINT staff_working_hours_staff_business_fk
        FOREIGN KEY (business_id, staff_id)
        REFERENCES staff_profiles (business_id, id)
        ON DELETE CASCADE;


-- Add a tenant-aware relationship for time_off.
ALTER TABLE time_off
    DROP CONSTRAINT time_off_staff_fk;

ALTER TABLE time_off
    ADD CONSTRAINT time_off_staff_business_fk
        FOREIGN KEY (business_id, staff_id)
        REFERENCES staff_profiles (business_id, id)
        ON DELETE CASCADE;