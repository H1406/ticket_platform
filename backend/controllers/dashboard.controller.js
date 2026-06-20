import {
  mockBookingHistory,
  mockLiveStats,
  mockNotifications,
  mockTrips
} from '../../shared/mock/transitData.js'

export function getDashboardSummary(_req, res) {
  res.json({
    liveStats: mockLiveStats,
    trips: mockTrips,
    bookingHistory: mockBookingHistory,
    notifications: mockNotifications
  })
}
