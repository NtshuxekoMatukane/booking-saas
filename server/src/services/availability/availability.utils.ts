import type {
  AvailabilityBlock,
  AvailabilityCandidate,
  AvailabilityWindow,
  TimeInterval,
} from "./availability.types.js";

export function intervalsOverlap(
  first: TimeInterval,
  second: TimeInterval
): boolean {
  return first.start < second.end && second.start < first.end;
}

export function intersectIntervals(
  first: TimeInterval,
  second: TimeInterval
): AvailabilityWindow | null {
  const start =
    first.start > second.start ? first.start : second.start;

  const end =
    first.end < second.end ? first.end : second.end;

  if (start >= end) {
    return null;
  }

  return {
    start,
    end,
  };
}

export function intersectWindowSets(
  firstWindows: AvailabilityWindow[],
  secondWindows: AvailabilityWindow[]
): AvailabilityWindow[] {
  const result: AvailabilityWindow[] = [];

  for (const first of firstWindows) {
    for (const second of secondWindows) {
      const intersection = intersectIntervals(first, second);

      if (intersection) {
        result.push(intersection);
      }
    }
  }

  return result.sort(
    (a, b) => a.start.getTime() - b.start.getTime()
  );
}

export function subtractBlockedIntervals(
  windows: AvailabilityWindow[],
  blocks: AvailabilityBlock[]
): AvailabilityWindow[] {
  if (blocks.length === 0) {
    return windows;
  }

  const sortedBlocks = [...blocks].sort(
    (a, b) => a.start.getTime() - b.start.getTime()
  );

  const result: AvailabilityWindow[] = [];

  for (const window of windows) {
    let cursor = window.start;

    for (const block of sortedBlocks) {
      if (!intervalsOverlap(window, block)) {
        continue;
      }

      if (block.start > cursor) {
        result.push({
          start: cursor,
          end:
            block.start < window.end
              ? block.start
              : window.end,
        });
      }

      if (block.end > cursor) {
        cursor = block.end;
      }

      if (cursor >= window.end) {
        break;
      }
    }

    if (cursor < window.end) {
      result.push({
        start: cursor,
        end: window.end,
      });
    }
  }

  return result;
}

export function generateCandidates(
  windows: AvailabilityWindow[],
  serviceDurationMinutes: number,
  bufferMinutes: number,
  slotIntervalMinutes: number
): AvailabilityCandidate[] {
  if (serviceDurationMinutes <= 0) {
    throw new Error(
      "Service duration must be greater than zero."
    );
  }

  if (bufferMinutes < 0) {
    throw new Error(
      "Buffer duration cannot be negative."
    );
  }

  if (slotIntervalMinutes <= 0) {
    throw new Error(
      "Slot interval must be greater than zero."
    );
  }

  const serviceDurationMs =
    serviceDurationMinutes * 60 * 1000;

  const totalBlockedDurationMs =
    (serviceDurationMinutes + bufferMinutes) *
    60 *
    1000;

  const stepMs =
    slotIntervalMinutes * 60 * 1000;

  const candidates: AvailabilityCandidate[] = [];

  for (const window of windows) {
    for (
      let startMs = window.start.getTime();
      startMs + totalBlockedDurationMs <=
      window.end.getTime();
      startMs += stepMs
    ) {
      const serviceStart = new Date(startMs);

      const serviceEnd = new Date(
        startMs + serviceDurationMs
      );

      const blockedUntil = new Date(
        startMs + totalBlockedDurationMs
      );

      candidates.push({
  serviceStart,
  serviceEnd,
  blockedUntil,
      });
    }
  }

  return candidates;
}

export function filterCandidatesAgainstBlocks(
  candidates: AvailabilityCandidate[],
  blocks: AvailabilityBlock[]
): AvailabilityCandidate[] {
  return candidates.filter((candidate) => {
    return !blocks.some((block) =>
      intervalsOverlap(
        {
          start: candidate.serviceStart,
          end: candidate.blockedUntil,
        },
        block
      )
    );
  });
}