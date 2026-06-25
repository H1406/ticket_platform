<script setup>
defineProps({
  trip: Object
})
</script>

<template>
  <div class="glass-panel p-4 h-auto">
    <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
      <div>
        <div class="small text-muted-soft">{{ trip.mode }}</div>
        <h3 class="h5 mb-1">{{ trip.route }}</h3>
      </div>
      <span class="badge-soft text-capitalize">{{ trip.status }}</span>
    </div>
    <div class="d-flex justify-content-between text-muted-soft">
      <span>{{ trip.date }} · {{ trip.departure }}</span>
      <span>{{ trip.seat }}</span>
    </div>
  </div>
</template>
