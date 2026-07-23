<script setup>
import { computed, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import MainLayout from '@/layouts/MainLayout.vue'
import SectionHeading from '@/components/common/SectionHeading.vue'
import SearchFilters from '@/components/search/SearchFilters.vue'
import SearchResultCard from '@/components/search/SearchResultCard.vue'
import { useBookingStore } from '@/stores/booking'

const router = useRouter()
const bookingStore = useBookingStore()

function formatDateInputValue(date = new Date()) {
  const timezoneOffsetMs = date.getTimezoneOffset() * 60 * 1000
  return new Date(date.getTime() - timezoneOffsetMs).toISOString().slice(0, 10)
}

onMounted(async () => {
  if (bookingStore.routes.length === 0) {
    await bookingStore.fetchRoutes()
  }
})

const form = reactive({
  departure: '',
  destination: '',
  departureDate: formatDateInputValue(),
  passengers: 1
})

const filters = reactive({
  vehicleType: '',
  type: '',
  time: ''
})

const filteredRoutes = computed(() =>
  bookingStore.routes.filter((route) => {
    const normalizedDeparture = form.departure.trim().toLowerCase()
    const normalizedDestination = form.destination.trim().toLowerCase()
    const normalizedVehicleType = filters.vehicleType.trim().toLowerCase()
    const matchesDeparture =
      !normalizedDeparture || route.departure.toLowerCase().includes(normalizedDeparture)
    const matchesDestination =
      !normalizedDestination || route.destination.toLowerCase().includes(normalizedDestination)
    const matchesType = !filters.type || route.type === filters.type
    const matchesVehicleType =
      !normalizedVehicleType || route.vehicleType.toLowerCase().includes(normalizedVehicleType)
    const matchesTime =
      !filters.time ||
      (filters.time === 'morning' && Number(route.departureTime.slice(0, 2)) < 12) ||
      (filters.time === 'afternoon' &&
        Number(route.departureTime.slice(0, 2)) >= 12 &&
        Number(route.departureTime.slice(0, 2)) < 18) ||
      (filters.time === 'night' && Number(route.departureTime.slice(0, 2)) >= 18)

    return (
      matchesDeparture &&
      matchesDestination &&
      matchesType &&
      matchesVehicleType &&
      matchesTime
    )
  })
)

async function selectRoute(route) {
  if (!form.departureDate) {
    form.departureDate = formatDateInputValue()
  }

  await bookingStore.selectRoute(route.id)
  bookingStore.resetSeatHold()
  router.push({
    name: 'seat-selection',
    query: { routeId: route.id, travelDate: form.departureDate }
  })
}
</script>

<template>
  <MainLayout>
    <section class="page-section pt-4">
      <div class="container">
        <SectionHeading
          eyebrow="Route Discovery"
          title="Search routes across rail and air inventory"
          copy="Browse live route inventory directly from Supabase and jump into realtime seat selection for the vehicle on that route."
        />

        <div class="row g-4">
          <div class="col-xl-3">
            <SearchFilters v-model="filters" />
          </div>

          <div class="col-xl-9">
            <div class="glass-panel p-4 mb-4">
              <div class="row g-3">
                <div class="col-md-6 col-lg-3">
                  <label class="form-label">Departure</label>
                  <input v-model="form.departure" type="text" class="form-control" />
                </div>
                <div class="col-md-6 col-lg-3">
                  <label class="form-label">Destination</label>
                  <input v-model="form.destination" type="text" class="form-control" />
                </div>
                <div class="col-md-6 col-lg-3">
                  <label class="form-label">Departure date</label>
                  <input v-model="form.departureDate" type="date" class="form-control" required />
                </div>
                <div class="col-md-6 col-lg-3">
                  <label class="form-label">Passengers</label>
                  <input v-model="form.passengers" type="number" min="1" max="9" class="form-control" />
                </div>
              </div>
            </div>

            <div class="d-flex flex-column gap-3">
              <div v-if="bookingStore.loading" class="glass-panel p-4">
                <h3 class="h5 mb-2">Loading routes</h3>
                <p class="text-muted-soft mb-0">Fetching the latest route inventory from Supabase.</p>
              </div>
              <div v-else-if="bookingStore.error" class="glass-panel p-4">
                <h3 class="h5 mb-2">Unable to load routes</h3>
                <p class="text-muted-soft mb-0">{{ bookingStore.error }}</p>
              </div>
              <SearchResultCard
                v-for="route in filteredRoutes"
                :key="route.id"
                :route="route"
                @select="selectRoute"
              />
              <div v-if="!bookingStore.loading && filteredRoutes.length === 0" class="glass-panel p-4">
                <h3 class="h5 mb-2">No routes found</h3>
                <p class="text-muted-soft mb-0">
                  Try adjusting the departure, destination, or filters to broaden the search.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </MainLayout>
</template>
