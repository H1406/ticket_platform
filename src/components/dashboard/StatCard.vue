<script setup>
defineProps({
  label: String,
  value: String,
  change: String
})
</script>

<template>
  <div class="glass-panel p-4 h-100 hover-lift">
    <div class="text-muted-soft small mb-2">{{ label }}</div>
    <div class="metric-value mb-2">{{ value }}</div>
    <div class="text-info small">{{ change }}</div>
  </div>
</template>
