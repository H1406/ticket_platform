<script setup>
import { onBeforeUnmount, ref } from 'vue'
import { Html5Qrcode } from 'html5-qrcode'
import { useBookingStore } from '@/stores/booking'

const bookingStore = useBookingStore()

const READER_ELEMENT_ID = 'admin-qr-reader'
const RESUME_DELAY_MS = 2000

// idle | starting | running | denied | unsupported | error
const scannerState = ref('idle')
const scannerError = ref('')
let html5Qrcode = null
let resumeTimeout = null

async function startScanner() {
  scannerError.value = ''

  if (!navigator.mediaDevices?.getUserMedia) {
    scannerState.value = 'unsupported'
    return
  }

  scannerState.value = 'starting'

  try {
    html5Qrcode = new Html5Qrcode(READER_ELEMENT_ID)
    await html5Qrcode.start(
      { facingMode: 'environment' },
      { fps: 10, qrbox: { width: 250, height: 250 } },
      onScanSuccess,
      () => {}
    )
    scannerState.value = 'running'
  } catch (err) {
    html5Qrcode = null

    if (err?.name === 'NotAllowedError' || /permission/i.test(String(err))) {
      scannerState.value = 'denied'
    } else if (err?.name === 'NotFoundError') {
      scannerState.value = 'unsupported'
    } else {
      scannerState.value = 'error'
      scannerError.value = err?.message || String(err)
    }
  }
}

async function stopScanner() {
  clearTimeout(resumeTimeout)

  if (html5Qrcode) {
    try {
      await html5Qrcode.stop()
      html5Qrcode.clear()
    } catch {
      // scanner was already stopped or never fully started
    }
    html5Qrcode = null
  }

  scannerState.value = 'idle'
}

async function onScanSuccess(decodedText) {
  if (!html5Qrcode) {
    return
  }

  html5Qrcode.pause(true)
  await bookingStore.checkInTicketFromQr(decodedText)

  resumeTimeout = setTimeout(() => {
    html5Qrcode?.resume()
  }, RESUME_DELAY_MS)
}

onBeforeUnmount(() => {
  stopScanner()
})
</script>

<template>
  <div class="glass-panel p-4">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h3 class="h5 mb-0">QR check-in scanner</h3>
      <span class="badge-soft">{{ scannerState }}</span>
    </div>

    <div
      id="admin-qr-reader"
      class="qr-reader mb-3"
      v-show="scannerState === 'running' || scannerState === 'starting'"
    ></div>

    <div class="d-flex flex-wrap gap-2 mb-3">
      <button v-if="scannerState === 'idle'" class="btn btn-tf-primary" @click="startScanner">
        Start scanner
      </button>
      <button v-else-if="scannerState === 'running'" class="btn btn-tf-secondary" @click="stopScanner">
        Stop scanner
      </button>
      <button
        v-else-if="['denied', 'error'].includes(scannerState)"
        class="btn btn-tf-secondary"
        @click="startScanner"
      >
        Retry
      </button>
    </div>

    <p v-if="scannerState === 'starting'" class="text-muted-soft small mb-3">Requesting camera access…</p>
    <p v-else-if="scannerState === 'denied'" class="text-muted-soft small mb-3">
      Camera permission was denied. Allow camera access for this site in your browser settings, then retry.
    </p>
    <p v-else-if="scannerState === 'unsupported'" class="text-muted-soft small mb-3">
      No usable camera was found, or this browser does not support camera-based scanning.
    </p>
    <p v-else-if="scannerState === 'error'" class="text-muted-soft small mb-3">
      Scanner error: {{ scannerError }}
    </p>

    <div v-if="bookingStore.checkInLoading" class="text-muted-soft small">Checking in ticket…</div>

    <div v-else-if="bookingStore.scanResult" class="glass-panel p-3 mt-2">
      <template v-if="bookingStore.scanResult.status === 'checked_in'">
        <div class="fw-semibold mb-1">Checked in</div>
        <div class="text-muted-soft small">
          {{ bookingStore.scanResult.passengerName || 'Passenger' }} · {{ bookingStore.scanResult.route }}
        </div>
      </template>
      <template v-else-if="bookingStore.scanResult.status === 'already_checked_in'">
        <div class="fw-semibold mb-1">Already checked in</div>
        <div class="text-muted-soft small">
          {{ bookingStore.scanResult.passengerName || 'Passenger' }} was already checked in
          <span v-if="bookingStore.scanResult.checkedInAt">
            at {{ new Date(bookingStore.scanResult.checkedInAt).toLocaleString() }}
          </span>.
        </div>
      </template>
      <template v-else-if="bookingStore.scanResult.status === 'expired'">
        <div class="fw-semibold mb-1">Ticket expired</div>
        <div class="text-muted-soft small">
          {{ bookingStore.scanResult.passengerName || 'Passenger' }} · {{ bookingStore.scanResult.route }} —
          departure time has passed, check-in blocked.
        </div>
      </template>
      <template v-else-if="bookingStore.scanResult.status === 'not_found'">
        <div class="fw-semibold mb-1">Unknown ticket</div>
        <div class="text-muted-soft small">This QR code does not match any ticket in the system.</div>
      </template>
      <template v-else>
        <div class="fw-semibold mb-1">Scan failed</div>
        <div class="text-muted-soft small">{{ bookingStore.scanResult.message }}</div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.qr-reader {
  max-width: 320px;
  margin: 0 auto;
  overflow: hidden;
  border-radius: var(--tf-radius-md);
}
</style>
