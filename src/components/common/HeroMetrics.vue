<script setup>
defineProps({
  metrics: {
    type: Array,
    default: () => []
  }
})
</script>

<template>
  <div class="row g-3 mt-2">
    <div v-for="metric in metrics" :key="metric.label" class="col-6 col-lg-3">
      <div class="glass-panel p-3 h-100">
        <div class="metric-value">{{ metric.value }}</div>
        <div class="text-muted-soft small">{{ metric.label }}</div>
      </div>
    </div>
  </div>
</template>
