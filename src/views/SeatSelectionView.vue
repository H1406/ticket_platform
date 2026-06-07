<script setup>
import { computed, ref } from 'vue'
import MainLayout from '@/layouts/MainLayout.vue'
import SectionHeading from '@/components/common/SectionHeading.vue'
import InteractiveSeatMap from '@/components/seatmap/InteractiveSeatMap.vue'
import SeatLegend from '@/components/seatmap/SeatLegend.vue'
import ReservationTimer from '@/components/seatmap/ReservationTimer.vue'
import { useBookingStore } from '@/stores/booking'
import { useRealtimeChannel } from '@/composables/useRealtimeChannel'
import { useReservationCountdown } from '@/composables/useReservationCountdown'

const bookingStore = useBookingStore()
const expiresAt = ref(bookingStore.holdExpiresAt)
const { minutes, seconds, isExpired } = useReservationCountdown(expiresAt)

// TODO: Replace mock socket handler with channel-specific seat updates from backend locks.
useRealtimeChannel({
  'seats:updated': () => {}
})

const selectedSummary = computed(() => bookingStore.selectedSeats.join(', '))

function handleToggleSeat(seatId) {
  bookingStore.toggleSeat(seatId)
}
</script>

<template>
  <MainLayout>
    <section class="page-section pt-4">
      <div class="container">
        <SectionHeading
          eyebrow="Seat Experience"
          title="Select seats in a realtime-ready visual map"
          copy="This SVG seat canvas supports multiple seat states, hover affordance, hold timing, and future synchronization with distributed locking."
        />

        <div class="row g-4">
          <div class="col-xl-8">
            <InteractiveSeatMap :seats="bookingStore.seatMap" @toggle-seat="handleToggleSeat" />
          </div>

          <div class="col-xl-4">
            <div class="glass-panel p-4 mb-4">
              <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                <div>
                  <h3 class="h5 mb-1">{{ bookingStore.selectedRoute.operator }}</h3>
                  <div class="text-muted-soft small">
                    {{ bookingStore.selectedRoute.departure }} → {{ bookingStore.selectedRoute.destination }}
                  </div>
                </div>
                <span class="badge-soft text-capitalize">{{ bookingStore.selectedRoute.type }}</span>
              </div>

              <ReservationTimer :minutes="minutes" :seconds="seconds" :expired="isExpired" />

              <div class="mt-4">
                <SeatLegend />
              </div>

              <div class="glass-panel p-3 mt-4">
                <div class="small text-muted-soft">Selected seats</div>
                <div class="fw-semibold">{{ selectedSummary || 'No seats selected yet' }}</div>
              </div>

              <div class="glass-panel p-3 mt-3">
                <div class="small text-muted-soft">Realtime sync placeholder</div>
                <div class="text-muted-soft small">
                  Socket listeners, seat locking events, and timer reconciliation will connect here in the next phase.
                </div>
              </div>

              <RouterLink to="/ticket" class="btn btn-tf-primary w-100 mt-4">Continue to Ticket</RouterLink>
            </div>
          </div>
        </div>
      </div>
    </section>
  </MainLayout>
</template>
