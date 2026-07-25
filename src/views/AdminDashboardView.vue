<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import AdminLayout from '@/layouts/AdminLayout.vue'
import AdminOperationsChart from '@/components/admin/AdminOperationsChart.vue'
import StatCard from '@/components/dashboard/StatCard.vue'
import PassengerTable from '@/components/admin/PassengerTable.vue'
import { useBookingStore } from '@/stores/booking'

const bookingStore = useBookingStore()
const operationsDate = ref(formatDateInputValue())

function formatDateInputValue(date = new Date()) {
  const timezoneOffsetMs = date.getTimezoneOffset() * 60 * 1000
  return new Date(date.getTime() - timezoneOffsetMs).toISOString().slice(0, 10)
}

onMounted(async () => {
  await Promise.all([
    bookingStore.fetchLiveStats(),
    bookingStore.fetchAdminTickets(),
    bookingStore.fetchAdminSeatMetrics(),
    bookingStore.fetchPassengerCheckInFeed()
  ])
  bookingStore.subscribeToPassengerCheckIns()
})

onBeforeUnmount(() => {
  bookingStore.unsubscribeFromPassengerCheckIns()
})

const ticketsForOperationsDate = computed(() =>
  bookingStore.adminTickets.filter((ticket) => ticket.travelDate === operationsDate.value)
)
const validTicketCount = computed(
  () => ticketsForOperationsDate.value.filter((ticket) => ticket.canCheckIn).length
)
const checkedInCount = computed(
  () => ticketsForOperationsDate.value.filter((ticket) => ticket.isCheckedIn).length
)
const expiredTicketCount = computed(
  () => ticketsForOperationsDate.value.filter((ticket) => ticket.isExpired && !ticket.isCheckedIn).length
)
const soldSeatCount = computed(() =>
  ticketsForOperationsDate.value.reduce((total, ticket) => total + (ticket.seatCount || 0), 0)
)
const totalSeatCount = computed(() => bookingStore.adminSeatMetrics.totalSeats || 0)
const seatFillPercent = computed(() => {
  if (!totalSeatCount.value) {
    return 0
  }

  return Math.min(100, Math.round((soldSeatCount.value / totalSeatCount.value) * 100))
})
const maxTicketBarValue = computed(() =>
  Math.max(1, ticketsForOperationsDate.value.length, checkedInCount.value)
)
const adminStats = computed(() => [
  { label: 'Tickets sold', value: String(ticketsForOperationsDate.value.length), change: 'For selected date' },
  { label: 'Ready for check-in', value: String(validTicketCount.value), change: 'Valid boarding passes' },
  { label: 'Checked in', value: String(checkedInCount.value), change: 'Camera scans confirmed' },
  { label: 'Expired', value: String(expiredTicketCount.value), change: 'Blocked at scan' }
])
const chartMetrics = computed(() => [
  {
    key: 'seat-fillness',
    label: 'Seat fillness',
    detail: `${soldSeatCount.value} of ${totalSeatCount.value} seats sold`,
    value: `${seatFillPercent.value}%`,
    percent: seatFillPercent.value,
    tone: 'info'
  },
  {
    key: 'tickets-sold',
    label: 'Tickets sold',
    detail: 'Issued tickets for this date',
    value: String(ticketsForOperationsDate.value.length),
    percent: Math.round((ticketsForOperationsDate.value.length / maxTicketBarValue.value) * 100),
    tone: 'warning'
  },
  {
    key: 'checked-in',
    label: 'Checked in',
    detail: 'Passengers scanned at the gate',
    value: String(checkedInCount.value),
    percent: Math.round((checkedInCount.value / maxTicketBarValue.value) * 100),
    tone: 'success'
  }
])
</script>

<template>
  <AdminLayout>
    <div class="mb-4">
      <span class="eyebrow mb-3">Admin Console</span>
      <h1 class="section-title mb-3">Operations overview</h1>
      <p class="section-copy mb-0">
        Monitor boarding, occupancy, route operations, and notification flows from a scalable admin shell.
      </p>
    </div>

    <div class="row g-4 mb-4">
      <div v-for="stat in adminStats" :key="stat.label" class="col-12 col-md-6 col-xxl-3">
        <StatCard v-bind="stat" />
      </div>
    </div>

    <div class="dashboard-grid mb-4">
      <div class="dashboard-col dashboard-col-main">
        <div class="glass-panel p-4">
          <div class="d-flex justify-content-between align-items-center mb-3">
            <h3 class="h5 mb-0">Seat and boarding chart</h3>
            <input
              v-model="operationsDate"
              type="date"
              class="form-control admin-date-control"
            />
          </div>
          <div v-if="bookingStore.adminTicketsLoading || bookingStore.adminSeatMetricsLoading" class="text-muted-soft small py-4">
            Loading operations metrics...
          </div>
          <div v-else-if="bookingStore.adminTicketsError || bookingStore.adminSeatMetricsError" class="text-danger small py-4">
            {{ bookingStore.adminTicketsError || bookingStore.adminSeatMetricsError }}
          </div>
          <AdminOperationsChart v-else :metrics="chartMetrics" />
        </div>
      </div>
      <div class="dashboard-col dashboard-col-aside">
        <div class="glass-panel p-4">
          <h3 class="h5 mb-3">Route management</h3>
          <div class="d-flex flex-column gap-3">
            <div class="glass-panel p-3">
              <div class="fw-semibold">Ticket operations</div>
              <div class="small text-muted-soft">
                {{ ticketsForOperationsDate.length }} tickets are sold for the selected operations date.
              </div>
              <RouterLink to="/admin/tickets" class="btn btn-tf-secondary btn-sm mt-3">
                Open ticket desk
              </RouterLink>
            </div>
            <div class="glass-panel p-3">
              <div class="fw-semibold">Realtime boarding feed</div>
              <div class="small text-muted-soft">
                {{ checkedInCount }} passengers checked in; {{ validTicketCount }} tickets remain ready for boarding.
              </div>
            </div>
            <div class="glass-panel p-3">
              <div class="fw-semibold">Notification orchestration</div>
              <div class="small text-muted-soft">Prepared for streaming passenger and operator alerts.</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <PassengerTable
      :passengers="bookingStore.passengerTable"
      :loading="bookingStore.passengerFeedLoading"
      :error="bookingStore.passengerFeedError"
    />
  </AdminLayout>
</template>

<style scoped>
.admin-date-control {
  width: 180px;
  min-height: 42px;
}

@media (max-width: 767px) {
  .admin-date-control {
    width: 100%;
  }
}
</style>
