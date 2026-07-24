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
          <div class="d-flex gap-2">
            <div class="badge-soft">{{ ticket.status }}</div>
            <div v-if="ticket.isExpired" class="badge-soft">Expired</div>
          </div>
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
              <div class="fw-semibold text-truncate">{{ ticket.id }}</div>
              <div class="text-muted-soft small text-truncate">Booking: {{ ticket.bookingId }}</div>
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
        <div class="glass-panel p-4 text-center ticket-qr-panel">
          <div class="ticket-qr-frame mx-auto mb-3">
          <img
            v-if="ticket.qrCodeDataUrl"
            :src="ticket.qrCodeDataUrl"
            alt="Ticket QR code"
            class="ticket-qr-image"
          />
          <div v-else class="ticket-qr-placeholder">
            QR
          </div>
          </div>
          <div class="small text-muted-soft ticket-qr-payload">QR payload: {{ ticket.qrPayload }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.ticket-qr-panel {
  overflow: hidden;
}

.ticket-qr-frame {
  display: grid;
  place-items: center;
  width: min(100%, 196px);
  aspect-ratio: 1;
  padding: 10px;
  border-radius: var(--tf-radius-md);
  background: #ffffff;
}

.ticket-qr-image,
.ticket-qr-placeholder {
  display: block;
  width: 100%;
  height: 100%;
}

.ticket-qr-image {
  object-fit: contain;
}

.ticket-qr-placeholder {
  display: grid;
  place-items: center;
  color: #07111f;
  font-weight: 700;
}

.ticket-qr-payload {
  overflow-wrap: anywhere;
}
</style>
