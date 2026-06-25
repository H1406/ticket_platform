import { defineStore } from 'pinia'
import { supabase } from '@/services/supabase'
import { generateTicketQrAssets } from '@/utils/ticketQr'
import { useAuthStore } from './auth'

const DEFAULT_HOLD_MINUTES = 5

function calculateDurationLabel(departureTime, arrivalTime) {
  if (!departureTime || !arrivalTime) {
    return ''
  }

  const [departureHour = 0, departureMinute = 0] = String(departureTime).split(':').map(Number)
  const [arrivalHour = 0, arrivalMinute = 0] = String(arrivalTime).split(':').map(Number)
  const departureTotal = departureHour * 60 + departureMinute
  let arrivalTotal = arrivalHour * 60 + arrivalMinute

  if (arrivalTotal < departureTotal) {
    arrivalTotal += 24 * 60
  }

  const totalMinutes = arrivalTotal - departureTotal
  const hours = Math.floor(totalMinutes / 60)
  const minutes = totalMinutes % 60

  return `${hours}h ${String(minutes).padStart(2, '0')}m`
}

function formatRoute(route) {
  const primaryVehicle = route.vehicles?.[0] ?? null

  return {
    id: route.id,
    type: String(route.transport_type || '').toLowerCase(),
    transportType: route.transport_type,
    departure: route.departure,
    destination: route.destination,
    departureTime: route.departure_time,
    arrivalTime: route.arrival_time,
    duration: calculateDurationLabel(route.departure_time, route.arrival_time),
    operator: primaryVehicle?.vehicle_code || route.transport_type,
    vehicleType: primaryVehicle?.vehicle_type || route.transport_type,
    capacity: primaryVehicle?.capacity || 0,
    deckLayout: primaryVehicle?.deck_layout || null,
    vehicles: route.vehicles || []
  }
}

function mapSeatRecord(seat, currentUserId, activeBookingId) {
  const meta = seat.position_meta || {}
  const isHeldByCurrentUser =
    seat.status === 'held' &&
    seat.held_by_user_id === currentUserId &&
    (!activeBookingId || seat.held_by_booking_id === activeBookingId)

  return {
    id: seat.id,
    code: seat.seat_code,
    x: Number(meta.x || 0),
    y: Number(meta.y || 0),
    class: seat.seat_class || 'standard',
    status: seat.status || 'available',
    holdExpiresAt: seat.hold_expires_at,
    heldByBookingId: seat.held_by_booking_id,
    heldByUserId: seat.held_by_user_id,
    isHeldByCurrentUser
  }
}

function formatPassengerName(profile, user) {
  const profileName = `${profile?.firstName || ''} ${profile?.lastName || ''}`.trim()
  const metadata = user?.user_metadata || {}
  const metadataName =
    `${metadata.given_name || metadata.first_name || ''} ${metadata.family_name || metadata.last_name || ''}`.trim()

  return profileName || metadataName || user?.email || 'Passenger'
}

async function resolveTicketQr(ticket) {
  if (!ticket?.id) {
    return {
      qrPayload: '',
      qrCodeDataUrl: '',
      qrCodeSvg: ''
    }
  }

  const qrPayload = ticket.qr_payload || ticket.id
  const qrAssets = await generateTicketQrAssets(qrPayload)

  return {
    qrPayload,
    qrCodeDataUrl: qrAssets.dataUrl,
    qrCodeSvg: qrAssets.svg
  }
}

export const useBookingStore = defineStore('booking', {
  state: () => ({
    trips: [],
    bookingHistory: [],
    liveStats: [],
    notifications: [],
    routes: [],
    selectedRoute: null,
    activeVehicleId: null,
    activeBookingId: null,
    seatMap: [],
    ticket: null,
    passengerTable: [],
    holdExpiresAt: null,
    loading: false,
    seatMapLoading: false,
    ticketLoading: false,
    confirmingBooking: false,
    error: '',
    seatMapError: '',
    ticketError: '',
    seatChannel: null
  }),
  getters: {
    upcomingTrips: (state) =>
      state.trips.filter((trip) => !['cancelled', 'expired'].includes(trip.status)),
    selectedSeats: (state) => state.seatMap.filter((seat) => seat.isHeldByCurrentUser),
    selectedSeatCodes() {
      return this.selectedSeats.map((seat) => seat.code)
    },
    selectedSeatCount() {
      return this.selectedSeats.length
    }
  },
  actions: {
    async fetchRoutes() {
      this.loading = true
      this.error = ''

      try {
        const { data, error } = await supabase
          .from('routes')
          .select(`
            id,
            transport_type,
            departure,
            destination,
            departure_time,
            arrival_time,
            vehicles(
              id,
              vehicle_code,
              vehicle_type,
              capacity,
              deck_layout
            )
          `)
          .order('departure', { ascending: true })

        if (error) {
          throw error
        }

        this.routes = (data || []).map(formatRoute)
      } catch (err) {
        this.error = err.message || 'Failed to fetch routes'
        this.routes = []
      } finally {
        this.loading = false
      }
    },

    async selectRoute(routeId) {
      if (!this.routes.length) {
        await this.fetchRoutes()
      }

      this.selectedRoute = this.routes.find((route) => route.id === routeId) || null
      this.activeVehicleId = this.selectedRoute?.vehicles?.[0]?.id || null
      this.activeBookingId = null
      this.seatMap = []
      this.holdExpiresAt = null
      this.ticket = null
      this.ticketError = ''
    },

    async fetchUserTrips() {
      const authStore = useAuthStore()

      if (!authStore.user?.id) {
        this.trips = []
        return
      }

      this.loading = true
      this.error = ''

      try {
        const { data, error } = await supabase
          .from('bookings')
          .select(`
            id,
            status,
            created_at,
            routes(departure, destination, departure_time),
            seat_ids
          `)
          .eq('user_id', authStore.user.id)
          .order('created_at', { ascending: false })

        if (error) {
          throw error
        }

        this.trips = (data || []).map((booking) => ({
          id: booking.id,
          route: `${booking.routes?.departure || ''} to ${booking.routes?.destination || ''}`,
          mode: 'Transportation',
          departure: booking.routes?.departure_time || '',
          date: new Date(booking.created_at).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
          }),
          seat: Array.isArray(booking.seat_ids) ? `${booking.seat_ids.length} seat(s)` : '0 seat(s)',
          status: booking.status || 'draft'
        }))
      } catch (err) {
        this.error = err.message || 'Failed to fetch trips'
        this.trips = []
      } finally {
        this.loading = false
      }
    },

    async fetchBookingHistory() {
      const authStore = useAuthStore()

      if (!authStore.user?.id) {
        this.bookingHistory = []
        return
      }

      this.loading = true
      this.error = ''

      try {
        const { data, error } = await supabase
          .from('bookings')
          .select(`
            id,
            status,
            seat_ids,
            routes(departure, destination)
          `)
          .eq('user_id', authStore.user.id)
          .order('created_at', { ascending: false })
          .limit(10)

        if (error) {
          throw error
        }

        this.bookingHistory = (data || []).map((booking) => ({
          id: booking.id,
          route: `${booking.routes?.departure || ''} to ${booking.routes?.destination || ''}`,
          amount: `${booking.seat_ids?.length || 0} seat(s)`,
          status: booking.status ? booking.status.charAt(0).toUpperCase() + booking.status.slice(1) : 'Draft'
        }))
      } catch (err) {
        this.error = err.message || 'Failed to fetch booking history'
        this.bookingHistory = []
      } finally {
        this.loading = false
      }
    },

    async fetchNotifications() {
      const authStore = useAuthStore()

      if (!authStore.user?.id) {
        this.notifications = []
        return
      }

      try {
        const { data, error } = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', authStore.user.id)
          .is('read_at', null)
          .order('created_at', { ascending: false })
          .limit(5)

        if (error) {
          throw error
        }

        this.notifications = (data || []).map((notification) => ({
          id: notification.id,
          title: notification.title,
          body: notification.message,
          tone: 'info'
        }))
      } catch (err) {
        console.error('Error fetching notifications:', err)
        this.notifications = []
      }
    },

    async fetchLiveStats() {
      try {
        const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
        const [bookingResult, confirmedResult, heldResult, ticketResult] = await Promise.all([
          supabase.from('bookings').select('id', { count: 'exact', head: true }).gte('created_at', since),
          supabase.from('bookings').select('id', { count: 'exact', head: true }).eq('status', 'confirmed'),
          supabase.from('seats').select('id', { count: 'exact', head: true }).eq('status', 'held'),
          supabase.from('tickets').select('id', { count: 'exact', head: true })
        ])

        if (bookingResult.error) throw bookingResult.error
        if (confirmedResult.error) throw confirmedResult.error
        if (heldResult.error) throw heldResult.error
        if (ticketResult.error) throw ticketResult.error

        this.liveStats = [
          { label: 'Bookings Today', value: String(bookingResult.count || 0), change: 'Live' },
          { label: 'Confirmed Bookings', value: String(confirmedResult.count || 0), change: 'Synced' },
          { label: 'Seats On Hold', value: String(heldResult.count || 0), change: 'Realtime' },
          { label: 'Tickets Issued', value: String(ticketResult.count || 0), change: 'Persisted' }
        ]
      } catch (err) {
        console.error('Error fetching live stats:', err)
        this.liveStats = []
      }
    },

    async fetchPassengerTable(routeId) {
      this.loading = true
      this.error = ''

      try {
        const { data, error } = await supabase
          .from('bookings')
          .select(`
            id,
            seat_ids,
            routes(departure, destination),
            profiles(first_name, last_name)
          `)
          .eq('route_id', routeId)
          .eq('status', 'confirmed')

        if (error) {
          throw error
        }

        this.passengerTable = (data || []).map((booking, index) => ({
          id: `P-${1001 + index}`,
          name: `${booking.profiles?.first_name || ''} ${booking.profiles?.last_name || ''}`.trim() || 'Passenger',
          route: `${booking.routes?.departure?.substring(0, 3) || ''}-${booking.routes?.destination?.substring(0, 3) || ''}`.toUpperCase(),
          seat: `${booking.seat_ids?.length || 0} seat(s)`,
          status: 'Confirmed'
        }))
      } catch (err) {
        this.error = err.message || 'Failed to fetch passenger table'
        this.passengerTable = []
      } finally {
        this.loading = false
      }
    },

    async fetchSeatMap(routeId = this.selectedRoute?.id) {
      const authStore = useAuthStore()

      if (!routeId) {
        this.seatMap = []
        return
      }

      if (!this.selectedRoute || this.selectedRoute.id !== routeId) {
        await this.selectRoute(routeId)
      }

      this.seatMapLoading = true
      this.seatMapError = ''

      try {
        await supabase.rpc('release_expired_seat_holds')

        const vehicleId = this.selectedRoute?.vehicles?.[0]?.id
        if (!vehicleId) {
          this.seatMap = []
          this.activeVehicleId = null
          this.holdExpiresAt = null
          return
        }

        this.activeVehicleId = vehicleId

        const { data, error } = await supabase
          .from('seats')
          .select(`
            id,
            seat_code,
            seat_class,
            status,
            position_meta,
            held_by_booking_id,
            held_by_user_id,
            hold_expires_at
          `)
          .eq('vehicle_id', vehicleId)
          .order('seat_code', { ascending: true })

        if (error) {
          throw error
        }

        this.seatMap = (data || []).map((seat) =>
          mapSeatRecord(seat, authStore.user?.id, this.activeBookingId)
        )

        const activeHeldSeat = this.seatMap.find((seat) => seat.isHeldByCurrentUser)
        this.activeBookingId = activeHeldSeat?.heldByBookingId || null
        this.holdExpiresAt = activeHeldSeat?.holdExpiresAt ? new Date(activeHeldSeat.holdExpiresAt).getTime() : null

        if (this.activeBookingId) {
          this.seatMap = this.seatMap.map((seat) => ({
            ...seat,
            isHeldByCurrentUser:
              seat.status === 'held' &&
              seat.heldByUserId === authStore.user?.id &&
              seat.heldByBookingId === this.activeBookingId
          }))
        }
      } catch (err) {
        this.seatMapError = err.message || 'Failed to fetch seat map'
        this.seatMap = []
      } finally {
        this.seatMapLoading = false
      }
    },

    subscribeToSeatUpdates() {
      if (!this.activeVehicleId) {
        return
      }

      this.unsubscribeFromSeatUpdates()

      const channel = supabase
        .channel(`seat-map:${this.activeVehicleId}`)
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'seats',
            filter: `vehicle_id=eq.${this.activeVehicleId}`
          },
          () => {
            void this.fetchSeatMap()
          }
        )
        .subscribe()

      this.seatChannel = channel
    },

    unsubscribeFromSeatUpdates() {
      if (this.seatChannel) {
        supabase.removeChannel(this.seatChannel)
        this.seatChannel = null
      }
    },

    async toggleSeat(seatId) {
      const seat = this.seatMap.find((item) => item.id === seatId)

      if (!seat) {
        return
      }

      this.seatMapError = ''

      try {
        if (seat.isHeldByCurrentUser) {
          const { error } = await supabase.rpc('release_seat_hold', {
            p_seat_id: seat.id,
            p_booking_id: this.activeBookingId
          })

          if (error) {
            throw error
          }
        } else {
          const { data, error } = await supabase.rpc('hold_seat', {
            p_route_id: this.selectedRoute?.id,
            p_seat_id: seat.id,
            p_booking_id: this.activeBookingId,
            p_hold_minutes: DEFAULT_HOLD_MINUTES
          })

          if (error) {
            throw error
          }

          const holdResult = data?.[0]
          this.activeBookingId = holdResult?.booking_id || this.activeBookingId
          this.holdExpiresAt = holdResult?.hold_expires_at
            ? new Date(holdResult.hold_expires_at).getTime()
            : this.holdExpiresAt
        }

        await this.fetchSeatMap()
      } catch (err) {
        this.seatMapError = err.message || 'Unable to update seat hold'
      }
    },

    async cancelActiveBooking() {
      if (!this.activeBookingId) {
        return
      }

      try {
        const { error } = await supabase.rpc('release_booking_holds', {
          p_booking_id: this.activeBookingId,
          p_cancel: true
        })

        if (error) {
          throw error
        }
      } catch (err) {
        console.error('Error cancelling booking holds:', err)
      } finally {
        this.activeBookingId = null
        this.holdExpiresAt = null
        await this.fetchSeatMap()
      }
    },

    resetSeatHold() {
      this.holdExpiresAt = null
      this.activeBookingId = null
      this.seatMap = []
      this.seatMapError = ''
    },

    async confirmBooking() {
      const authStore = useAuthStore()

      if (!authStore.user?.id) {
        this.ticketError = 'Please sign in to complete your booking.'
        return null
      }

      if (!this.activeBookingId) {
        this.ticketError = 'Select at least one seat before confirming.'
        return null
      }

      this.confirmingBooking = true
      this.ticketError = ''

      try {
        const { data, error } = await supabase.rpc('confirm_booking', {
          p_booking_id: this.activeBookingId
        })

        if (error) {
          throw error
        }

        const confirmation = data?.[0]
        if (!confirmation?.ticket_id) {
          throw new Error('Ticket creation did not return an ID.')
        }

        const ticket = await this.fetchTicket(confirmation.ticket_id)
        this.activeBookingId = null
        await Promise.allSettled([
          this.fetchUserTrips(),
          this.fetchBookingHistory(),
          this.fetchNotifications(),
          this.fetchLiveStats(),
          this.fetchSeatMap()
        ])

        this.holdExpiresAt = null
        return ticket
      } catch (err) {
        this.ticketError = err.message || 'Unable to confirm booking'
        return null
      } finally {
        this.confirmingBooking = false
      }
    },

    async fetchTicket(ticketId) {
      const authStore = useAuthStore()

      if (!ticketId) {
        this.ticket = null
        return null
      }

      this.ticketLoading = true
      this.ticketError = ''

      try {
        const { data, error } = await supabase
          .from('tickets')
          .select(`
            id,
            booking_id,
            qr_payload,
            boarding_status,
            issued_at,
            bookings(
              id,
              route_id,
              status,
              created_at,
              seat_ids,
              routes(departure, destination, departure_time, arrival_time, transport_type)
            )
          `)
          .eq('id', ticketId)
          .maybeSingle()

        if (error) {
          throw error
        }

        if (!data) {
          throw new Error('Ticket not found.')
        }

        const seatIds = data.bookings?.seat_ids || []
        let seatCodes = []

        if (seatIds.length) {
          const { data: seatData, error: seatError } = await supabase
            .from('seats')
            .select('id, seat_code, seat_class')
            .in('id', seatIds)

          if (seatError) {
            throw seatError
          }

          seatCodes = (seatData || []).map((seat) => seat.seat_code).sort()
        }

        const passenger = formatPassengerName(authStore.profile, authStore.user)
        const qrFields = await resolveTicketQr(data)

        this.ticket = {
          id: data.id,
          bookingId: data.booking_id,
          route: `${data.bookings?.routes?.departure || ''} → ${data.bookings?.routes?.destination || ''}`,
          operator:
            this.selectedRoute?.operator ||
            data.bookings?.routes?.transport_type ||
            `${data.bookings?.routes?.departure || 'Route'} service`,
          passenger,
          passengerEmail: authStore.profile?.email || authStore.user?.email || '',
          departureDate: data.bookings?.created_at
            ? new Date(data.bookings.created_at).toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric'
              })
            : '',
          departureTime: data.bookings?.routes?.departure_time || '',
          arrivalTime: data.bookings?.routes?.arrival_time || '',
          seat: seatCodes.join(', ') || 'Seat unavailable',
          class: `${seatIds.length} seat(s)`,
          gate: 'Assigned at check-in',
          status: data.boarding_status || data.bookings?.status || 'confirmed',
          qrPayload: qrFields.qrPayload,
          qrCodeDataUrl: qrFields.qrCodeDataUrl,
          qrCodeSvg: qrFields.qrCodeSvg
        }

        return this.ticket
      } catch (err) {
        this.ticketError = err.message || 'Failed to load ticket'
        this.ticket = null
        return null
      } finally {
        this.ticketLoading = false
      }
    },

    async fetchLatestTicket() {
      this.ticketLoading = true
      this.ticketError = ''

      try {
        const { data, error } = await supabase
          .from('tickets')
          .select('id, issued_at')
          .order('issued_at', { ascending: false })
          .limit(1)

        if (error) {
          throw error
        }

        const latestTicketId = data?.[0]?.id
        if (!latestTicketId) {
          this.ticket = null
          return null
        }

        return await this.fetchTicket(latestTicketId)
      } catch (err) {
        this.ticketError = err.message || 'Failed to load latest ticket'
        this.ticket = null
        return null
      } finally {
        this.ticketLoading = false
      }
    }
  }
})
