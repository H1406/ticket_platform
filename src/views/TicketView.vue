<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import MainLayout from '@/layouts/MainLayout.vue'
import SectionHeading from '@/components/common/SectionHeading.vue'
import TicketCard from '@/components/ticket/TicketCard.vue'
import TicketListItem from '@/components/ticket/TicketListItem.vue'
import TicketStatusBadge from '@/components/ticket/TicketStatusBadge.vue'
import { useBookingStore } from '@/stores/booking'

const route = useRoute()
const router = useRouter()
const bookingStore = useBookingStore()

const selectedTicketId = ref('')
const requestedTicketId = ref('')
const currentPage = ref(1)
const ticketsPerPage = 5

const selectedTicket = computed(
  () => bookingStore.tickets.find((ticket) => ticket.id === selectedTicketId.value) || null
)

const totalPages = computed(() => Math.ceil(bookingStore.tickets.length / ticketsPerPage) || 1)

const pageStartIndex = computed(() => (currentPage.value - 1) * ticketsPerPage)

const paginatedTickets = computed(() =>
  bookingStore.tickets.slice(pageStartIndex.value, pageStartIndex.value + ticketsPerPage)
)

const paginationSummary = computed(() => {
  if (!bookingStore.tickets.length) {
    return '0 tickets'
  }

  const start = pageStartIndex.value + 1
  const end = Math.min(pageStartIndex.value + ticketsPerPage, bookingStore.tickets.length)

  return `${start}-${end} of ${bookingStore.tickets.length} tickets`
})

const requestedTicketMissing = computed(
  () =>
    Boolean(requestedTicketId.value) &&
    !bookingStore.ticketsLoading &&
    !bookingStore.tickets.some((ticket) => ticket.id === requestedTicketId.value)
)

function selectTicket(ticketId) {
  selectedTicketId.value = ticketId
  router.replace({ query: { ...route.query, ticketId } })
}

function setCurrentPage(page) {
  const nextPage = Math.min(Math.max(page, 1), totalPages.value)

  if (nextPage === currentPage.value) {
    return
  }

  currentPage.value = nextPage

  if (!paginatedTickets.value.some((ticket) => ticket.id === selectedTicketId.value)) {
    selectTicket(paginatedTickets.value[0]?.id || '')
  }
}

function setPageForTicket(ticketId) {
  const ticketIndex = bookingStore.tickets.findIndex((ticket) => ticket.id === ticketId)

  if (ticketIndex >= 0) {
    currentPage.value = Math.floor(ticketIndex / ticketsPerPage) + 1
  }
}

function downloadQrCode() {
  if (!selectedTicket.value?.qrCodeDataUrl) {
    return
  }

  const link = document.createElement('a')
  link.href = selectedTicket.value.qrCodeDataUrl
  link.download = `ticket-${selectedTicket.value.id}.png`
  link.click()
}

onMounted(async () => {
  requestedTicketId.value = typeof route.query.ticketId === 'string' ? route.query.ticketId : ''

  await bookingStore.fetchUserTickets()

  if (requestedTicketId.value && bookingStore.tickets.some((ticket) => ticket.id === requestedTicketId.value)) {
    selectedTicketId.value = requestedTicketId.value
    setPageForTicket(requestedTicketId.value)
  } else if (bookingStore.tickets.length) {
    selectedTicketId.value = bookingStore.tickets[0].id
  }
})
</script>

<template>
  <MainLayout>
    <section class="page-section pt-4">
      <div class="container">
        <SectionHeading
          eyebrow="Boarding Pass"
          title="Your tickets"
          copy="Every ticket below reflects a real, persisted Supabase record with its own QR boarding pass."
        />

        <div v-if="bookingStore.ticketsLoading" class="glass-panel p-4">
          <h3 class="h5 mb-2">Loading tickets</h3>
          <p class="text-muted-soft mb-0">Fetching your tickets from Supabase.</p>
        </div>

        <div v-else-if="bookingStore.ticketsError" class="glass-panel p-4">
          <h3 class="h5 mb-2">Unable to load tickets</h3>
          <p class="text-muted-soft mb-0">{{ bookingStore.ticketsError }}</p>
        </div>

        <div v-else-if="!bookingStore.tickets.length" class="glass-panel p-4">
          <h3 class="h5 mb-2">No tickets yet</h3>
          <p class="text-muted-soft mb-3">Book a route to generate your first ticket and QR boarding pass.</p>
          <router-link class="btn btn-tf-primary" to="/search">Search routes</router-link>
        </div>

        <template v-else>
          <div v-if="requestedTicketMissing" class="glass-panel p-3 mb-3">
            <p class="text-muted-soft mb-0">
              The ticket requested in the link was not found or is not accessible to your account.
            </p>
          </div>

          <div class="row g-4">
            <div class="col-lg-5">
              <div class="d-flex flex-column gap-3">
                <TicketListItem
                  v-for="ticket in paginatedTickets"
                  :key="ticket.id"
                  :ticket="ticket"
                  :selected="ticket.id === selectedTicketId"
                  @select="selectTicket"
                />
              </div>

              <div class="ticket-pagination mt-3" aria-label="Ticket pagination">
                <div class="text-muted-soft small">{{ paginationSummary }}</div>

                <div class="d-flex flex-wrap align-items-center gap-2">
                  <button
                    type="button"
                    class="btn btn-tf-secondary btn-sm"
                    :disabled="currentPage === 1"
                    @click="setCurrentPage(currentPage - 1)"
                  >
                    Previous
                  </button>

                  <button
                    v-for="pageNumber in totalPages"
                    :key="pageNumber"
                    type="button"
                    class="btn btn-sm ticket-page-button"
                    :class="pageNumber === currentPage ? 'btn-tf-primary' : 'btn-tf-secondary'"
                    :aria-current="pageNumber === currentPage ? 'page' : undefined"
                    @click="setCurrentPage(pageNumber)"
                  >
                    {{ pageNumber }}
                  </button>

                  <button
                    type="button"
                    class="btn btn-tf-secondary btn-sm"
                    :disabled="currentPage === totalPages"
                    @click="setCurrentPage(currentPage + 1)"
                  >
                    Next
                  </button>
                </div>
              </div>
            </div>

            <div class="col-lg-7">
              <template v-if="selectedTicket">
                <TicketCard :ticket="selectedTicket" />

                <div class="row g-4 mt-1">
                  <div class="col-sm-6">
                    <div class="glass-panel p-4 h-100">
                      <h3 class="h5 mb-3">Boarding status</h3>
                      <TicketStatusBadge
                        class="mb-2"
                        :status="selectedTicket.boardingStatus"
                        :expired="selectedTicket.isExpired"
                      />
                      <p v-if="selectedTicket.checkedInAt" class="text-muted-soft small mb-0">
                        Checked in at {{ new Date(selectedTicket.checkedInAt).toLocaleString() }}
                      </p>
                      <p v-else-if="selectedTicket.isExpired" class="text-muted-soft small mb-0">
                        This ticket's departure time has passed and it can no longer be checked in.
                      </p>
                      <p v-else class="text-muted-soft small mb-0">
                        Ready for check-in at boarding.
                      </p>
                    </div>
                  </div>
                  <div class="col-sm-6">
                    <div class="glass-panel p-4 h-100">
                      <h3 class="h5 mb-3">Actions</h3>
                      <button class="btn btn-tf-primary" @click="downloadQrCode">Download QR Code</button>
                    </div>
                  </div>
                </div>
              </template>

              <div v-else class="glass-panel p-4">
                <h3 class="h5 mb-2">Select a ticket</h3>
                <p class="text-muted-soft mb-0">Choose a ticket from the list to see its full details and QR code.</p>
              </div>
            </div>
          </div>
        </template>
      </div>
    </section>
  </MainLayout>
</template>
