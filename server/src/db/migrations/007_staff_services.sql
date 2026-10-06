CREATE TABLE staff_services (
    business_id UUID NOT NULL,

    staff_id UUID NOT NULL,

    service_id UUID NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT staff_services_business_fk
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
        ON DELETE CASCADE,

    CONSTRAINT staff_services_staff_fk
        FOREIGN KEY (staff_id)
        REFERENCES staff_profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT staff_services_service_fk
        FOREIGN KEY (service_id)
        REFERENCES services(id)
        ON DELETE CASCADE,

    CONSTRAINT staff_services_pk
        PRIMARY KEY (business_id, staff_id, service_id)
);