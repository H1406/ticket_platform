<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { onBeforeRouteLeave, useRoute, useRouter } from 'vue-router'
import MainLayout from '@/layouts/MainLayout.vue'
import SectionHeading from '@/components/common/SectionHeading.vue'
import InteractiveSeatMap from '@/components/seatmap/InteractiveSeatMap.vue'
import SeatLegend from '@/components/seatmap/SeatLegend.vue'
import ReservationTimer from '@/components/seatmap/ReservationTimer.vue'
import { useBookingStore } from '@/stores/booking'
import { useReservationCountdown } from '@/composables/useReservationCountdown'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const bookingStore = useBookingStore()
const expiresAt = ref(bookingStore.holdExpiresAt)
const { minutes, seconds, isExpired } = useReservationCountdown(expiresAt)

const selectedSummary = computed(() => bookingStore.selectedSeatCodes.join(', '))
const activeRoute = computed(() => bookingStore.selectedRoute)
const canContinue = computed(() => bookingStore.selectedSeatCount > 0 && !bookingStore.confirmingBooking)
const passengerSummary = computed(() =>
  `${authStore.fullName} · ${authStore.profile?.email || authStore.user?.email || ''}`
)

async function loadSeatSelection(routeId) {
  if (!routeId) {
    await bookingStore.fetchRoutes()

    const fallbackRouteId = bookingStore.routes[0]?.id
    if (!fallbackRouteId) {
      return
    }

    await router.replace({ name: 'seat-selection', query: { routeId: fallbackRouteId } })
    return
  }

  await bookingStore.selectRoute(routeId)
  await bookingStore.fetchSeatMap(routeId)
  bookingStore.subscribeToSeatUpdates()
}

async function handleToggleSeat(seatId) {
  await bookingStore.toggleSeat(seatId)
}

async function continueToTicket() {
  const ticket = await bookingStore.confirmBooking()

  if (ticket?.id) {
    router.push({ name: 'ticket', query: { ticketId: ticket.id } })
  }
}

async function releaseBookingFlow() {
  bookingStore.unsubscribeFromSeatUpdates()

  if (bookingStore.activeBookingId) {
    await bookingStore.cancelActiveBooking()
  }
}

function handlePageHide() {
  void releaseBookingFlow()
}

watch(
  () => bookingStore.holdExpiresAt,
  (value) => {
    expiresAt.value = value
  },
  { immediate: true }
)

watch(isExpired, async (expired) => {
  if (!expired || !bookingStore.activeBookingId) {
    return
  }

  await bookingStore.fetchSeatMap()
})

watch(
  () => route.query.routeId,
  async (routeId) => {
    if (typeof routeId === 'string') {
      await loadSeatSelection(routeId)
    }
  },
  { immediate: true }
)

onMounted(() => {
  if (typeof route.query.routeId !== 'string') {
    void loadSeatSelection('')
  }

  window.addEventListener('pagehide', handlePageHide)
})

onBeforeUnmount(() => {
  bookingStore.unsubscribeFromSeatUpdates()
  window.removeEventListener('pagehide', handlePageHide)
})

onBeforeRouteLeave(async (to) => {
  if (to.name !== 'ticket') {
    await releaseBookingFlow()
  }
})
</script>

<template>
  <MainLayout>
    <section class="page-section pt-4">
      <div class="container">
        <SectionHeading
          eyebrow="Seat Experience"
          title="Select seats with live Supabase availability"
          copy="Seat states are read directly from the database, held in Supabase during checkout, and synchronized instantly across connected clients."
        />

        <div class="row g-4">
          <div class="col-xl-8">
            <InteractiveSeatMap :seats="bookingStore.seatMap" @toggle-seat="handleToggleSeat" />
            <div v-if="bookingStore.seatMapLoading" class="glass-panel p-4 mt-4">
              <h3 class="h5 mb-2">Loading seat map</h3>
              <p class="text-muted-soft mb-0">Fetching the latest seat layout and statuses from Supabase.</p>
            </div>
            <div v-else-if="bookingStore.seatMapError" class="glass-panel p-4 mt-4">
              <h3 class="h5 mb-2">Seat map unavailable</h3>
              <p class="text-muted-soft mb-0">{{ bookingStore.seatMapError }}</p>
            </div>
            <div v-else-if="bookingStore.seatMap.length === 0" class="glass-panel p-4 mt-4">
              <h3 class="h5 mb-2">No seats found</h3>
              <p class="text-muted-soft mb-0">This route does not currently have any seat records in Supabase.</p>
            </div>
          </div>

          <div class="col-xl-4">
            <div class="glass-panel p-4 mb-4">
              <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                <div>
                  <h3 class="h5 mb-1">{{ activeRoute?.operator || 'Select a route first' }}</h3>
                  <div class="text-muted-soft small">
                    {{ activeRoute?.departure || 'Departure' }} → {{ activeRoute?.destination || 'Destination' }}
                  </div>
                </div>
                <span class="badge-soft text-capitalize">{{ activeRoute?.type || 'transport' }}</span>
              </div>

              <ReservationTimer
                v-if="bookingStore.holdExpiresAt"
                :minutes="minutes"
                :seconds="seconds"
                :expired="isExpired"
              />

              <div class="glass-panel p-3 mt-4">
                <div class="small text-muted-soft">Passenger</div>
                <div class="fw-semibold">{{ passengerSummary }}</div>
                <div class="text-muted-soft small mt-1">
                  Ticket details will be autofilled from your Supabase account profile.
                </div>
              </div>

              <div class="mt-4">
                <SeatLegend />
              </div>

              <div class="glass-panel p-3 mt-4">
                <div class="small text-muted-soft">Selected seats</div>
                <div class="fw-semibold">{{ selectedSummary || 'No seats selected yet' }}</div>
              </div>

              <div class="glass-panel p-3 mt-3">
                <div class="small text-muted-soft">Realtime status</div>
                <div class="text-muted-soft small">
                  {{ bookingStore.selectedSeatCount }} seat(s) are currently held for this booking flow.
                </div>
              </div>

              <div v-if="bookingStore.ticketError" class="glass-panel p-3 mt-3">
                <div class="small text-muted-soft">Booking issue</div>
                <div class="text-danger small">{{ bookingStore.ticketError }}</div>
              </div>

              <button
                class="btn btn-tf-primary w-100 mt-4"
                :disabled="!canContinue"
                @click="continueToTicket"
              >
                {{ bookingStore.confirmingBooking ? 'Confirming booking...' : 'Confirm Booking' }}
              </button>

              <button
                v-if="bookingStore.activeBookingId"
                class="btn btn-tf-secondary w-100 mt-3"
                @click="bookingStore.cancelActiveBooking()"
              >
                Cancel Booking
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  </MainLayout>
</template>
