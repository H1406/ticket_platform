import { defineStore } from 'pinia'
import {
  mockBookingHistory,
  mockLiveStats,
  mockNotifications,
  mockPassengerTable,
  mockRoutes,
  mockSeatMap,
  mockTicket,
  mockTrips
} from '@/mock/data'

export const useBookingStore = defineStore('booking', {
  state: () => ({
    trips: mockTrips,
    bookingHistory: mockBookingHistory,
    liveStats: mockLiveStats,
    notifications: mockNotifications,
    routes: mockRoutes,
    selectedRoute: mockRoutes[0],
    seatMap: mockSeatMap,
    selectedSeats: ['B4'],
    ticket: mockTicket,
    passengerTable: mockPassengerTable,
    holdExpiresAt: Date.now() + 1000 * 60 * 14
  }),
  getters: {
    upcomingTrips: (state) => state.trips.filter((trip) => trip.status !== 'completed'),
    selectedSeatCount: (state) => state.selectedSeats.length
  },
  actions: {
    selectRoute(route) {
      this.selectedRoute = route
    },
    toggleSeat(seatId) {
      const seat = this.seatMap.find((item) => item.id === seatId)

      if (!seat || ['reserved', 'occupied'].includes(seat.status)) {
        return
      }

      if (this.selectedSeats.includes(seatId)) {
        this.selectedSeats = this.selectedSeats.filter((item) => item !== seatId)
        seat.status = 'available'
        return
      }

      this.selectedSeats.push(seatId)
      seat.status = 'selected'
    },
    resetSeatHold(minutes = 14) {
      this.holdExpiresAt = Date.now() + 1000 * 60 * minutes
    }
  }
})
