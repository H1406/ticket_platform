<script setup>
import { onMounted } from 'vue'
import { useRoute } from 'vue-router'
import MainLayout from '@/layouts/MainLayout.vue'
import SectionHeading from '@/components/common/SectionHeading.vue'
import TicketCard from '@/components/ticket/TicketCard.vue'
import { useBookingStore } from '@/stores/booking'

const route = useRoute()
const bookingStore = useBookingStore()

function downloadQrCode() {
  if (!bookingStore.ticket?.qrCodeDataUrl) {
    return
  }

  const link = document.createElement('a')
  link.href = bookingStore.ticket.qrCodeDataUrl
  link.download = `ticket-${bookingStore.ticket.id}.png`
  link.click()
}

onMounted(async () => {
  const ticketId = typeof route.query.ticketId === 'string' ? route.query.ticketId : ''

  if (ticketId) {
    await bookingStore.fetchTicket(ticketId)
    return
  }

  if (!bookingStore.ticket?.id) {
    await bookingStore.fetchLatestTicket()
  }
})
</script>

<template>
  <MainLayout>
    <section class="page-section pt-4">
      <div class="container">
        <SectionHeading
          eyebrow="Boarding Pass"
          title="Persisted ticket with QR generated from the stored ticket ID"
          copy="Each QR code is generated only after the booking creates a real ticket record in Supabase, so the code always encodes the persisted ticket ID."
        />

        <div v-if="bookingStore.ticketLoading" class="glass-panel p-4">
          <h3 class="h5 mb-2">Loading ticket</h3>
          <p class="text-muted-soft mb-0">Fetching the latest persisted ticket details from Supabase.</p>
        </div>

        <div v-else-if="bookingStore.ticketError" class="glass-panel p-4">
          <h3 class="h5 mb-2">Unable to load ticket</h3>
          <p class="text-muted-soft mb-0">{{ bookingStore.ticketError }}</p>
        </div>

        <template v-else-if="bookingStore.ticket">
          <TicketCard :ticket="bookingStore.ticket" />

          <div class="row g-4 mt-1">
            <div class="col-lg-6">
              <div class="glass-panel p-4 h-100">
                <h3 class="h5 mb-3">Boarding status</h3>
                <div class="badge-soft mb-3">Current state: {{ bookingStore.ticket.status }}</div>
                <p class="text-muted-soft mb-0">
                  The passenger name and email on this ticket were autofilled from the authenticated Supabase account.
                </p>
              </div>
            </div>
            <div class="col-lg-6">
              <div class="glass-panel p-4 h-100">
                <h3 class="h5 mb-3">Actions</h3>
                <button class="btn btn-tf-primary me-2 mb-2" @click="downloadQrCode">Download QR Code</button>
                <div class="text-muted-soft small mt-2">
                  Download the generated QR image for offline access or sharing.
                </div>
              </div>
            </div>
          </div>
        </template>

        <div v-else class="glass-panel p-4">
          <h3 class="h5 mb-2">No ticket yet</h3>
          <p class="text-muted-soft mb-0">Confirm a booking first to generate a ticket and QR code.</p>
        </div>
      </div>
    </section>
  </MainLayout>
</template>
