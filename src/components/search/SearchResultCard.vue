<script setup>
defineProps({
  route: Object
})

const emit = defineEmits(['select'])
</script>

<template>
  <div class="glass-panel p-4 hover-lift">
    <div class="d-flex flex-column flex-lg-row justify-content-between gap-4">
      <div>
        <div class="badge-soft mb-3 text-capitalize">
          {{ route.transportType }} · {{ route.vehicleType }}
        </div>
        <h3 class="h5 mb-2">{{ route.departure }} → {{ route.destination }}</h3>
        <div class="text-muted-soft">
          {{ route.operator }} · {{ route.departureTime }} - {{ route.arrivalTime }} · {{ route.duration }}
        </div>
      </div>
      <div class="text-lg-end">
        <div class="metric-value mb-2">{{ route.capacity }} seats</div>
        <button class="btn btn-tf-primary" @click="emit('select', route)">Choose Seat</button>
      </div>
    </div>
  </div>
</template>
