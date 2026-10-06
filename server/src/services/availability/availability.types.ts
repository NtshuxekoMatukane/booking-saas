export interface TimeInterval {
  start: Date;
  end: Date;
}

export interface AvailabilityBlock extends TimeInterval {
  type: "APPOINTMENT" | "TIME_OFF";
}

export interface AvailabilityWindow extends TimeInterval {}

export interface AvailabilityCandidate {
  serviceStart: Date;
  serviceEnd: Date;
  blockedUntil: Date;
}

export interface AvailabilityRequest {
  businessId: string;
  staffId: string;
  serviceId: string;
  localDate: string;
  slotIntervalMinutes?: number;
}

export interface AvailabilityResult {
  businessId: string;
  staffId: string;
  serviceId: string;
  localDate: string;
  timezone: string;
  slotIntervalMinutes: number;
  slots: string[];
}