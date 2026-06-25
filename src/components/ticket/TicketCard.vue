<script setup>
defineProps({
  ticket: Object
})
</script>

<template>
  <div class="glass-panel-strong p-4 p-lg-5 position-relative">
    <div class="row g-4 align-items-center">
      <div class="col-lg-8">
        <div class="d-flex justify-content-between flex-wrap gap-3 mb-4">
          <div>
            <div class="text-muted-soft small">Digital Boarding Pass</div>
            <h2 class="h3 mb-1">{{ ticket.route }}</h2>
            <div class="text-muted-soft">{{ ticket.operator }}</div>
          </div>
          <div class="badge-soft">{{ ticket.status }}</div>
        </div>

        <div class="row g-3">
          <div class="col-sm-6">
            <div class="glass-panel p-3 h-100">
              <div class="small text-muted-soft">Passenger</div>
              <div class="fw-semibold">{{ ticket.passenger }}</div>
              <div class="text-muted-soft small">{{ ticket.passengerEmail }}</div>
            </div>
          </div>
          <div class="col-sm-6">
            <div class="glass-panel p-3 h-100">
              <div class="small text-muted-soft">Ticket ID</div>
              <div class="fw-semibold">{{ ticket.id }}</div>
            </div>
          </div>
          <div class="col-sm-4">
            <div class="glass-panel p-3 h-100">
              <div class="small text-muted-soft">Departure</div>
              <div class="fw-semibold">{{ ticket.departureDate }}</div>
              <div class="text-muted-soft small">{{ ticket.departureTime }}</div>
            </div>
          </div>
          <div class="col-sm-4">
            <div class="glass-panel p-3 h-100">
              <div class="small text-muted-soft">Seat</div>
              <div class="fw-semibold">{{ ticket.seat }}</div>
              <div class="text-muted-soft small">{{ ticket.class }}</div>
            </div>
          </div>
          <div class="col-sm-4">
            <div class="glass-panel p-3 h-100">
              <div class="small text-muted-soft">Gate / Platform</div>
              <div class="fw-semibold">{{ ticket.gate }}</div>
              <div class="text-muted-soft small">Arrival {{ ticket.arrivalTime }}</div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-lg-4">
        <div class="glass-panel p-4 text-center">
          <img
            v-if="ticket.qrCodeDataUrl"
            :src="ticket.qrCodeDataUrl"
            alt="Ticket QR code"
            class="mx-auto mb-3 rounded-4 bg-light p-2"
            style="width: 180px; height: 180px;"
          />
          <div v-else class="mx-auto mb-3 d-grid place-items-center rounded-4 bg-light text-dark" style="width: 180px; height: 180px;">
            QR
          </div>
          <div class="small text-muted-soft">QR payload: {{ ticket.qrPayload }}</div>
        </div>
      </div>
    </div>
  </div>
</template>
