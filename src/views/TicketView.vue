<script setup>
import MainLayout from '@/layouts/MainLayout.vue'
import SectionHeading from '@/components/common/SectionHeading.vue'
import TicketCard from '@/components/ticket/TicketCard.vue'
import { useBookingStore } from '@/stores/booking'

const bookingStore = useBookingStore()
</script>

<template>
  <MainLayout>
    <section class="page-section pt-4">
      <div class="container">
        <SectionHeading
          eyebrow="Boarding Pass"
          title="Digital tickets ready for QR and live boarding status"
          copy="The ticket surface is designed for downloadable passes, QR issuance, boarding updates, and future gate scan validation."
        />

        <TicketCard :ticket="bookingStore.ticket" />

        <div class="row g-4 mt-1">
          <div class="col-lg-6">
            <div class="glass-panel p-4 h-100">
              <h3 class="h5 mb-3">Boarding status</h3>
              <div class="badge-soft mb-3">Current state: {{ bookingStore.ticket.status }}</div>
              <p class="text-muted-soft mb-0">
                TODO: Stream boarding transitions from realtime check-in services and trigger user notifications when gate or platform assignments change.
              </p>
            </div>
          </div>
          <div class="col-lg-6">
            <div class="glass-panel p-4 h-100">
              <h3 class="h5 mb-3">Actions</h3>
              <button class="btn btn-tf-primary me-2 mb-2">Download Ticket</button>
              <button class="btn btn-tf-secondary mb-2">Share Boarding Pass</button>
              <div class="text-muted-soft small mt-2">
                Download/export actions are UI placeholders for future PDF or wallet pass generation.
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </MainLayout>
</template>
