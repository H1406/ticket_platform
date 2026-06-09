import { defineStore } from 'pinia'
import { supabase } from '@/services/supabase'
import { useAuthStore } from './auth'

export const useBookingStore = defineStore('booking', {
  state: () => ({
    trips: [],
    bookingHistory: [],
    liveStats: [],
    notifications: [],
    routes: [],
    selectedRoute: null,
    seatMap: [],
    selectedSeats: [],
    ticket: null,
    passengerTable: [],
    holdExpiresAt: Date.now() + 1000 * 60 * 14,
    loading: false,
    error: ''
  }),
  getters: {
    upcomingTrips: (state) => state.trips.filter((trip) => trip.status !== 'completed'),
    selectedSeatCount: (state) => state.selectedSeats.length
  },
  actions: {
    async fetchRoutes() {
      try {
        this.loading = true
        this.error = ''

        const { data, error } = await supabase
          .from('routes')
          .select(`
            id,
            transport_type,
            departure,
            destination,
            departure_time,
            arrival_time,
            vehicles(id, vehicle_type, capacity)
          `)

        if (error) throw error

        this.routes = data.map((route) => ({
          id: route.id,
          type: route.transport_type?.toLowerCase() || 'train',
          operator: `${route.transport_type} Service`,
          departure: route.departure,
          destination: route.destination,
          departureTime: route.departure_time,
          arrivalTime: route.arrival_time,
          price: '$0',
          duration: '0h',
          class: 'Standard'
        }))

        if (this.routes.length > 0) {
          this.selectedRoute = this.routes[0]
        }
      } catch (err) {
        this.error = err.message || 'Failed to fetch routes'
        console.error('Error fetching routes:', err)
      } finally {
        this.loading = false
      }
    },

    async fetchUserTrips() {
      try {
        this.loading = true
        this.error = ''

        const authStore = useAuthStore()
        if (!authStore.user?.id) {
          this.trips = []
          return
        }

        const { data, error } = await supabase
          .from('bookings')
          .select(`
            id,
            status,
            hold_expires_at,
            routes(departure, destination, departure_time),
            tickets(id, boarding_status)
          `)
          .eq('user_id', authStore.user.id)
          .order('created_at', { ascending: false })

        if (error) throw error

        this.trips = data.map((booking) => ({
          id: booking.id,
          route: `${booking.routes?.departure || ''} to ${booking.routes?.destination || ''}`,
          mode: 'Transportation',
          departure: booking.routes?.departure_time || '',
          date: new Date(booking.created_at).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
          }),
          seat: 'TBD',
          status: booking.status || 'pending'
        }))
      } catch (err) {
        this.error = err.message || 'Failed to fetch trips'
        console.error('Error fetching trips:', err)
      } finally {
        this.loading = false
      }
    },

    async fetchBookingHistory() {
      try {
        this.loading = true
        this.error = ''

        const authStore = useAuthStore()
        if (!authStore.user?.id) {
          this.bookingHistory = []
          return
        }

        const { data, error } = await supabase
          .from('bookings')
          .select(`
            id,
            status,
            routes(departure, destination)
          `)
          .eq('user_id', authStore.user.id)
          .order('created_at', { ascending: false })
          .limit(10)

        if (error) throw error

        this.bookingHistory = data.map((booking) => ({
          id: booking.id,
          route: `${booking.routes?.departure || ''} to ${booking.routes?.destination || ''}`,
          amount: '$0',
          status: booking.status?.charAt(0).toUpperCase() + booking.status?.slice(1) || 'Pending'
        }))
      } catch (err) {
        this.error = err.message || 'Failed to fetch booking history'
        console.error('Error fetching booking history:', err)
      } finally {
        this.loading = false
      }
    },

    async fetchNotifications() {
      try {
        const authStore = useAuthStore()
        if (!authStore.user?.id) {
          this.notifications = []
          return
        }

        const { data, error } = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', authStore.user.id)
          .eq('read_at', null)
          .order('created_at', { ascending: false })
          .limit(5)

        if (error) throw error

        this.notifications = data.map((notif) => ({
          id: notif.id,
          title: notif.title,
          body: notif.message,
          tone: 'info'
        }))
      } catch (err) {
        console.error('Error fetching notifications:', err)
        this.notifications = []
      }
    },

    async fetchSeatMap(vehicleId) {
      try {
        this.loading = true
        this.error = ''

        const { data, error } = await supabase
          .from('seats')
          .select('id, seat_code, seat_class, status, position_meta')
          .eq('vehicle_id', vehicleId)

        if (error) throw error

        this.seatMap = data.map((seat) => {
          const meta = seat.position_meta || {}
          return {
            id: seat.seat_code,
            x: meta.x || 0,
            y: meta.y || 0,
            status: seat.status || 'available',
            class: seat.seat_class || 'standard'
          }
        })
      } catch (err) {
        this.error = err.message || 'Failed to fetch seat map'
        console.error('Error fetching seat map:', err)
      } finally {
        this.loading = false
      }
    },

    async fetchLiveStats() {
      try {
        // Query aggregated stats from bookings and checkins
        const { data: bookingStats, error: bookingError } = await supabase
          .from('bookings')
          .select('id')
          .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())

        const { data: checkinStats, error: checkinError } = await supabase
          .from('checkins')
          .select('id')

        if (bookingError) throw bookingError
        if (checkinError) throw checkinError

        this.liveStats = [
          { label: 'Bookings Today', value: bookingStats?.length || '0', change: '+14%' },
          { label: 'Live Occupancy', value: '82%', change: '+5.3%' },
          { label: 'Check-ins Synced', value: checkinStats?.length || '0', change: 'Realtime-ready' },
          { label: 'Support Resolution', value: '97%', change: '+2.1%' }
        ]
      } catch (err) {
        console.error('Error fetching live stats:', err)
        this.liveStats = []
      }
    },

    async fetchPassengerTable(routeId) {
      try {
        this.loading = true
        this.error = ''

        const { data, error } = await supabase
          .from('bookings')
          .select(`
            id,
            routes(departure, destination),
            profiles(first_name, last_name)
          `)
          .eq('route_id', routeId)
          .eq('status', 'confirmed')

        if (error) throw error

        this.passengerTable = data.map((booking, idx) => ({
          id: `P-${1001 + idx}`,
          name: `${booking.profiles?.first_name || ''} ${booking.profiles?.last_name || ''}`.trim(),
          route: `${booking.routes?.departure?.substring(0, 3)}-${booking.routes?.destination?.substring(0, 3)}`.toUpperCase(),
          seat: 'TBD',
          status: 'Pending'
        }))
      } catch (err) {
        this.error = err.message || 'Failed to fetch passenger table'
        console.error('Error fetching passenger table:', err)
      } finally {
        this.loading = false
      }
    },

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
