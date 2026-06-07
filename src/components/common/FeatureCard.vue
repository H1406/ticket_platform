<script setup>
defineProps({
  title: String,
  description: String,
  icon: String
})
</script>

<template>
  <div class="glass-panel h-100 p-4 hover-lift">
    <div class="badge-soft mb-3">{{ icon }}</div>
    <h3 class="h5">{{ title }}</h3>
    <p class="text-muted-soft mb-0">{{ description }}</p>
  </div>
</template>
