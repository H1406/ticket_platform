<script setup>
import { computed } from 'vue'

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
    held: '#ffbd59',
    booked: '#ff6b7a'
  }[status]
}

function seatOpacity(status, isHeldByCurrentUser) {
  if (isHeldByCurrentUser) {
    return 1
  }

  return status === 'booked' ? 0.75 : 0.9
}

function seatLabelFill(seat) {
  return seat.isHeldByCurrentUser ? '#05251a' : '#05101a'
}

function seatDisplayFill(seat) {
  return seat.isHeldByCurrentUser ? '#39d98a' : seatFill(seat.status)
}

const layoutMetrics = computed(() => {
  if (!props.seats.length) {
    return {
      viewBox: '0 0 420 370',
      deck: { x: 6, y: 6, width: 408, height: 358 },
      aisle: { x: 180, y: 18, width: 60, height: 330, labelX: 210, labelY: 42 },
      sideRails: [
        { x: 14, y: 140, width: 26, height: 80 },
        { x: 380, y: 140, width: 26, height: 80 }
      ]
    }
  }

  const seatWidth = 50
  const seatHeight = 54
  const minX = Math.min(...props.seats.map((seat) => seat.x))
  const maxX = Math.max(...props.seats.map((seat) => seat.x + seatWidth))
  const minY = Math.min(...props.seats.map((seat) => seat.y - 10))
  const maxY = Math.max(...props.seats.map((seat) => seat.y + seatHeight))
  const horizontalPadding = 42
  const verticalPadding = 34
  const deckX = Math.max(minX - horizontalPadding, 0)
  const deckY = Math.max(minY - verticalPadding, 0)
  const deckWidth = Math.max(maxX - minX + horizontalPadding * 2, 320)
  const deckHeight = Math.max(maxY - minY + verticalPadding * 2, 260)
  const viewBox = `${deckX} ${deckY} ${deckWidth} ${deckHeight}`
  const aisleX = deckX + deckWidth / 2 - 30
  const aisleY = deckY + 16
  const aisleHeight = Math.max(deckHeight - 32, 120)

  return {
    viewBox,
    deck: {
      x: deckX + 6,
      y: deckY + 6,
      width: Math.max(deckWidth - 12, 308),
      height: Math.max(deckHeight - 12, 208)
    },
    aisle: {
      x: aisleX,
      y: aisleY,
      width: 60,
      height: aisleHeight,
      labelX: aisleX + 30,
      labelY: aisleY + 24
    },
    sideRails: [
      {
        x: deckX + 14,
        y: deckY + deckHeight / 2 - 40,
        width: 26,
        height: 80
      },
      {
        x: deckX + deckWidth - 40,
        y: deckY + deckHeight / 2 - 40,
        width: 26,
        height: 80
      }
    ]
  }
})
</script>

<template>
  <div class="glass-panel-strong p-3 p-lg-4">
    <div class="d-flex justify-content-between align-items-center flex-wrap gap-3 mb-4">
      <div>
        <h3 class="h5 mb-1">Realtime seat canvas</h3>
        <div class="text-muted-soft small">SVG-based layout ready for future sync events and locking states</div>
      </div>
      <div class="badge-soft">Vehicle view: Live Supabase seat inventory</div>
    </div>

    <svg :viewBox="layoutMetrics.viewBox" class="w-100">
      <defs>
        <linearGradient id="deckGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="rgba(255,255,255,0.08)" />
          <stop offset="100%" stop-color="rgba(255,255,255,0.02)" />
        </linearGradient>
      </defs>

      <rect
        :x="layoutMetrics.deck.x"
        :y="layoutMetrics.deck.y"
        :width="layoutMetrics.deck.width"
        :height="layoutMetrics.deck.height"
        rx="30"
        fill="url(#deckGradient)"
        stroke="rgba(255,255,255,0.1)"
      />
      <rect
        :x="layoutMetrics.aisle.x"
        :y="layoutMetrics.aisle.y"
        :width="layoutMetrics.aisle.width"
        :height="layoutMetrics.aisle.height"
        rx="24"
        fill="rgba(255,255,255,0.03)"
      />
      <text
        :x="layoutMetrics.aisle.labelX"
        :y="layoutMetrics.aisle.labelY"
        text-anchor="middle"
        fill="#9fb2cf"
        font-size="12"
      >
        Aisle
      </text>

      <g>
        <rect
          v-for="(rail, index) in layoutMetrics.sideRails"
          :key="index"
          :x="rail.x"
          :y="rail.y"
          :width="rail.width"
          :height="rail.height"
          rx="12"
          fill="rgba(255,255,255,0.06)"
        />
      </g>

      <g v-for="seat in props.seats" :key="seat.id" @click="emit('toggle-seat', seat.id)" style="cursor: pointer;">
        <rect
          :x="seat.x"
          :y="seat.y"
          width="50"
          height="54"
          rx="18"
          :fill="seatDisplayFill(seat)"
          :fill-opacity="seatOpacity(seat.status, seat.isHeldByCurrentUser)"
          stroke="rgba(255,255,255,0.22)"
          stroke-width="2"
        />
        <rect
          :x="seat.x + 8"
          :y="seat.y - 10"
          width="34"
          height="12"
          rx="6"
          :fill="seatDisplayFill(seat)"
          :fill-opacity="0.6"
        />
        <text
          :x="seat.x + 25"
          :y="seat.y + 32"
          text-anchor="middle"
          :fill="seatLabelFill(seat)"
          font-size="14"
          font-weight="700"
        >
          {{ seat.code }}
        </text>
      </g>
    </svg>
  </div>
</template>
