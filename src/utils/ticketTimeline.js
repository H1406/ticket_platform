export function resolveDepartureDateTime({ travelDate, departureTime, referenceDate }) {
  const dateValue = travelDate || referenceDate

  if (!dateValue) {
    return null
  }

  const base = new Date(dateValue)
  if (Number.isNaN(base.getTime())) {
    return null
  }

  if (departureTime) {
    const [hours = 0, minutes = 0, seconds = 0] = String(departureTime).split(':').map(Number)
    base.setHours(hours, minutes, seconds || 0, 0)
  }

  return base
}

export function getTicketTimelineStatus({
  travelDate,
  departureTime,
  boardingStatus,
  now = new Date(),
  referenceDate
}) {
  // Legacy rows created before `bookings.travel_date` fall back to their booking date.
  const departureDateTime = resolveDepartureDateTime({ travelDate, departureTime, referenceDate })
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
