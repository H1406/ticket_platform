<script setup>
defineProps({
  minutes: String,
  seconds: String,
  expired: Boolean
})
</script>

<template>
  <div class="glass-panel p-3 d-inline-flex align-items-center gap-3">
    <span class="small text-muted-soft">Temporary seat hold</span>
    <strong :class="expired ? 'text-danger' : 'text-warning'">
      {{ expired ? 'Expired' : `${minutes}:${seconds}` }}
    </strong>
  </div>
</template>
