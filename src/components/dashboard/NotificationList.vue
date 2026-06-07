<script setup>
defineProps({
  notifications: {
    type: Array,
    default: () => []
  }
})
</script>

<template>
  <div class="glass-panel p-4 h-100">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h3 class="h5 mb-0">Notifications</h3>
      <span class="text-muted-soft small">Realtime-ready feed</span>
    </div>

    <div class="d-flex flex-column gap-3">
      <div
        v-for="item in notifications"
        :key="item.id"
        class="p-3 rounded-4"
        :class="{
          'bg-warning bg-opacity-10': item.tone === 'warning',
          'bg-success bg-opacity-10': item.tone === 'success',
          'bg-info bg-opacity-10': item.tone === 'info'
        }"
      >
        <div class="fw-semibold mb-1">{{ item.title }}</div>
        <div class="text-muted-soft small">{{ item.body }}</div>
      </div>
    </div>
  </div>
</template>
