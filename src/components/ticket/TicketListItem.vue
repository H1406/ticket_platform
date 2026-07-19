<script setup>
defineProps({
  ticket: Object,
  selected: Boolean
})

defineEmits(['select'])
</script>

<template>
  <button
    type="button"
    class="glass-panel p-3 w-100 text-start ticket-list-item"
    :class="{ 'ticket-list-item-active': selected }"
    @click="$emit('select', ticket.id)"
  >
    <div class="d-flex justify-content-between align-items-start gap-2 mb-2">
      <div class="fw-semibold">{{ ticket.route }}</div>
      <span class="badge-soft">{{ ticket.timelineLabel }}</span>
    </div>
    <div class="text-muted-soft small mb-1">{{ ticket.passenger }} · Seat {{ ticket.seat }}</div>
    <div class="text-muted-soft small d-flex flex-wrap gap-2">
      <span>{{ ticket.departureDate }} {{ ticket.departureTime }}</span>
      <span>·</span>
      <span>Status: {{ ticket.status }}</span>
      <span v-if="ticket.isCheckedIn">· Checked in</span>
    </div>
  </button>
</template>

<style scoped>
.ticket-list-item {
  border: 1px solid transparent;
  cursor: pointer;
}

.ticket-list-item-active {
  border-color: var(--tf-primary);
}
</style>
