// The schema has no `travel_date` / `departure_at` timestamp on `routes` or `bookings` —
// only a `time`-only `routes.departure_time`. As the best available approximation we combine
// the booking's `created_at` date with the route's departure time to get a departure instant.
export function resolveDepartureDateTime({ referenceDate, departureTime }) {
  if (!referenceDate) {
    return null
  }

  const base = new Date(referenceDate)
  if (Number.isNaN(base.getTime())) {
    return null
  }

  if (departureTime) {
    const [hours = 0, minutes = 0, seconds = 0] = String(departureTime).split(':').map(Number)
    base.setHours(hours, minutes, seconds || 0, 0)
  }

  return base
}

export function getTicketTimelineStatus({ referenceDate, departureTime, boardingStatus, now = new Date() }) {
  const departureDateTime = resolveDepartureDateTime({ referenceDate, departureTime })
  const isCheckedIn = boardingStatus === 'checked_in'
  const isExpired = Boolean(departureDateTime) && now.getTime() > departureDateTime.getTime()

  let label = 'Valid'
  if (isCheckedIn) {
    label = 'Checked in'
  } else if (isExpired) {
    label = 'Expired'
  }

  return {
    departureDateTime,
    isCheckedIn,
    isExpired,
    canCheckIn: !isExpired && !isCheckedIn,
    label
  }
}
