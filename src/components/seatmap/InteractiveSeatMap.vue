<script setup>
const props = defineProps({
  seats: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['toggle-seat'])

function seatFill(status) {
  return {
    available: '#4dd2ff',
    selected: '#39d98a',
    reserved: '#ffbd59',
    occupied: '#ff6b7a'
  }[status]
}

function seatOpacity(status) {
  return status === 'occupied' ? 0.75 : 1
}
</script>

<template>
  <div class="glass-panel-strong p-3 p-lg-4">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
      <div>
        <h3 class="h5 mb-1">Realtime seat canvas</h3>
        <div class="text-muted-soft small">SVG-based layout ready for future sync events and locking states</div>
      </div>
      <div class="badge-soft">Vehicle view: Premium Coach / Narrow-body cabin</div>
    </div>

    <svg viewBox="0 0 420 370" class="w-100">
      <defs>
        <linearGradient id="deckGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="rgba(255,255,255,0.08)" />
          <stop offset="100%" stop-color="rgba(255,255,255,0.02)" />
        </linearGradient>
      </defs>

      <rect x="6" y="6" width="408" height="358" rx="30" fill="url(#deckGradient)" stroke="rgba(255,255,255,0.1)" />
      <rect x="180" y="18" width="60" height="330" rx="24" fill="rgba(255,255,255,0.03)" />
      <text x="210" y="42" text-anchor="middle" fill="#9fb2cf" font-size="12">Aisle</text>

      <g>
        <rect x="14" y="140" width="26" height="80" rx="12" fill="rgba(255,255,255,0.06)" />
        <rect x="380" y="140" width="26" height="80" rx="12" fill="rgba(255,255,255,0.06)" />
      </g>

      <g v-for="seat in props.seats" :key="seat.id" @click="emit('toggle-seat', seat.id)" style="cursor: pointer;">
        <rect
          :x="seat.x"
          :y="seat.y"
          width="50"
          height="54"
          rx="18"
          :fill="seatFill(seat.status)"
          :fill-opacity="seatOpacity(seat.status)"
          stroke="rgba(255,255,255,0.22)"
          stroke-width="2"
        />
        <rect
          :x="seat.x + 8"
          :y="seat.y - 10"
          width="34"
          height="12"
          rx="6"
          :fill="seatFill(seat.status)"
          :fill-opacity="0.6"
        />
        <text
          :x="seat.x + 25"
          :y="seat.y + 32"
          text-anchor="middle"
          fill="#05101a"
          font-size="14"
          font-weight="700"
        >
          {{ seat.id }}
        </text>
      </g>
    </svg>
  </div>
</template>
