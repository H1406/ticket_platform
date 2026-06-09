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

onMounted(async () => {
  if (bookingStore.routes.length === 0) {
    await bookingStore.fetchRoutes()
  }
})

const form = reactive({
  departure: 'Hanoi',
  destination: 'Da Nang',
  departureDate: '2026-06-04',
  passengers: 1
})

const filters = reactive({
  price: 180,
  type: '',
  time: ''
})

const filteredRoutes = computed(() =>
  bookingStore.routes.filter((route) => {
    const numericPrice = Number(route.price.replace(/[^0-9]/g, ''))
    const matchesType = !filters.type || route.type === filters.type
    const matchesPrice = numericPrice <= filters.price
    const matchesTime =
      !filters.time ||
      (filters.time === 'morning' && Number(route.departureTime.slice(0, 2)) < 12) ||
      (filters.time === 'afternoon' &&
        Number(route.departureTime.slice(0, 2)) >= 12 &&
        Number(route.departureTime.slice(0, 2)) < 18) ||
      (filters.time === 'night' && Number(route.departureTime.slice(0, 2)) >= 18)

    return matchesType && matchesPrice && matchesTime
  })
)

function selectRoute(route) {
  bookingStore.selectRoute(route)
  bookingStore.resetSeatHold()
  router.push('/seat-selection')
}
</script>

<template>
  <MainLayout>
    <section class="page-section pt-4">
      <div class="container">
        <SectionHeading
          eyebrow="Route Discovery"
          title="Search routes across rail and air inventory"
          copy="This MVP search flow is built to evolve into API-backed availability, dynamic pricing, and conversational assistance."
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
                  <input v-model="form.departureDate" type="date" class="form-control" />
                </div>
                <div class="col-md-6 col-lg-3">
                  <label class="form-label">Passengers</label>
                  <input v-model="form.passengers" type="number" min="1" max="9" class="form-control" />
                </div>
              </div>
            </div>

            <div class="d-flex flex-column gap-3">
              <SearchResultCard
                v-for="route in filteredRoutes"
                :key="route.id"
                :route="route"
                @select="selectRoute"
              />
            </div>
          </div>
        </div>
      </div>
    </section>
  </MainLayout>
</template>
