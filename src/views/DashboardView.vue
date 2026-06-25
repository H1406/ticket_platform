<script setup>
import { onMounted } from 'vue'
import MainLayout from '@/layouts/MainLayout.vue'
import SectionHeading from '@/components/common/SectionHeading.vue'
import StatCard from '@/components/dashboard/StatCard.vue'
import TripCard from '@/components/dashboard/TripCard.vue'
import NotificationList from '@/components/dashboard/NotificationList.vue'
import { useAuthStore } from '@/stores/auth'
import { useBookingStore } from '@/stores/booking'

const authStore = useAuthStore()
const bookingStore = useBookingStore()

onMounted(async () => {
  // Load all dashboard data
  await Promise.all([
    bookingStore.fetchLiveStats(),
    bookingStore.fetchUserTrips(),
    bookingStore.fetchBookingHistory(),
    bookingStore.fetchNotifications()
  ])
})
</script>

<template>
  <MainLayout>
    <section class="page-section pt-4">
      <div class="container">
        <SectionHeading
          eyebrow="Workspace"
          :title="`Welcome back, ${authStore.profile?.firstName || 'Traveler'}`"
          copy="Your dashboard brings together live trip context, booking performance, notifications, and recent activity in one responsive operations view."
        />

        <div class="dashboard-grid mb-4">
          <div class="dashboard-col dashboard-col-main">
            <div class="row g-4">
              <div v-for="stat in bookingStore.liveStats" :key="stat.label" class="col-12 col-md-6 col-xxl-3">
                <StatCard v-bind="stat" />
              </div>
            </div>

            <div class="glass-panel p-4 mt-4">
              <div class="d-flex justify-content-between align-items-center mb-3">
                <h3 class="h4 mb-0">Upcoming trips</h3>
                <RouterLink to="/search" class="btn btn-tf-secondary">Book another trip</RouterLink>
              </div>
              <div class="row g-3">
                <div v-for="trip in bookingStore.upcomingTrips" :key="trip.id" class="col-md-6">
                  <TripCard :trip="trip" />
                </div>
              </div>
            </div>

            <div class="glass-panel p-4 mt-4">
              <div class="d-flex justify-content-between align-items-center mb-3">
                <h3 class="h4 mb-0">Booking history</h3>
                <span class="text-muted-soft small">Recent activity</span>
              </div>
              <div class="table-responsive">
                <table class="table table-dark table-borderless align-middle mb-0">
                  <thead>
                    <tr class="text-muted-soft">
                      <th>Booking ID</th>
                      <th>Route</th>
                      <th>Amount</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="row in bookingStore.bookingHistory" :key="row.id">
                      <td>{{ row.id }}</td>
                      <td>{{ row.route }}</td>
                      <td>{{ row.amount }}</td>
                      <td><span class="badge-soft">{{ row.status }}</span></td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div class="dashboard-col dashboard-col-aside">
            <NotificationList :notifications="bookingStore.notifications" />

            <div class="glass-panel p-4 mt-4">
              <h3 class="h5 mb-3">Realtime booking snapshot</h3>
              <div class="d-flex flex-column gap-3">
                <div
                  v-for="stat in bookingStore.liveStats.slice(0, 3)"
                  :key="stat.label"
                  class="glass-panel p-3"
                >
                  <div class="fw-semibold">{{ stat.label }}</div>
                  <div class="small text-muted-soft">{{ stat.value }} · {{ stat.change }}</div>
                </div>
                <div v-if="bookingStore.liveStats.length === 0" class="glass-panel p-3">
                  <div class="small text-muted-soft">No live metrics are available right now.</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </MainLayout>
</template>
