<script setup>
import { onMounted } from 'vue'
import AdminLayout from '@/layouts/AdminLayout.vue'
import StatCard from '@/components/dashboard/StatCard.vue'
import PassengerTable from '@/components/admin/PassengerTable.vue'
import { useBookingStore } from '@/stores/booking'

const bookingStore = useBookingStore()

onMounted(async () => {
  // Load live stats for admin dashboard
  await bookingStore.fetchLiveStats()
})

const adminStats = [
  { label: 'Active boardings', value: '12', change: 'Gate events queued' },
  { label: 'Live occupancy', value: '81%', change: 'Across tracked routes' },
  { label: 'Seat conflicts', value: '03', change: 'Prepared for lock resolution' },
  { label: 'Alerts dispatched', value: '46', change: 'Mock stream' }
]
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
            <h3 class="h5 mb-0">Occupancy chart placeholder</h3>
            <span class="text-muted-soft small">Chart library can be added later</span>
          </div>
          <div class="d-flex align-items-end gap-3 dashboard-chart">
            <div class="bg-info rounded-top-4 w-100 dashboard-chart-bar" style="--bar-height: 60%"></div>
            <div class="bg-success rounded-top-4 w-100 dashboard-chart-bar" style="--bar-height: 85%"></div>
            <div class="bg-warning rounded-top-4 w-100 dashboard-chart-bar" style="--bar-height: 72%"></div>
            <div class="bg-primary rounded-top-4 w-100 dashboard-chart-bar" style="--bar-height: 93%"></div>
            <div class="bg-danger rounded-top-4 w-100 dashboard-chart-bar" style="--bar-height: 48%"></div>
          </div>
        </div>
      </div>
      <div class="dashboard-col dashboard-col-aside">
        <div class="glass-panel p-4">
          <h3 class="h5 mb-3">Route management</h3>
          <div class="d-flex flex-column gap-3">
            <div class="glass-panel p-3">
              <div class="fw-semibold">Inventory publishing</div>
              <div class="small text-muted-soft">TODO: connect to Supabase CRUD and operator workflows.</div>
            </div>
            <div class="glass-panel p-3">
              <div class="fw-semibold">Realtime boarding feed</div>
              <div class="small text-muted-soft">TODO: merge sockets and check-in events by route and gate.</div>
            </div>
            <div class="glass-panel p-3">
              <div class="fw-semibold">Notification orchestration</div>
              <div class="small text-muted-soft">Prepared for streaming passenger and operator alerts.</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <PassengerTable :passengers="bookingStore.passengerTable" />
  </AdminLayout>
</template>
