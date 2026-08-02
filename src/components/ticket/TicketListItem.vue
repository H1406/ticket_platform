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
  color: var(--tf-text);
  cursor: pointer;
  transition: border-color 0.2s ease, background 0.2s ease, transform 0.2s ease;
}

.ticket-list-item:hover,
.ticket-list-item:focus-visible {
  border-color: rgba(77, 210, 255, 0.42);
  background: rgba(18, 34, 58, 0.88);
  color: var(--tf-text);
  transform: translateY(-1px);
  outline: none;
}

.ticket-list-item .fw-semibold {
  color: var(--tf-text);
}

.ticket-list-item-active {
  border-color: var(--tf-primary);
  background: rgba(77, 210, 255, 0.14);
  color: var(--tf-text);
  box-shadow: 0 18px 44px rgba(77, 210, 255, 0.12);
}

.ticket-list-item-active .badge-soft {
  color: var(--tf-text);
  border: 1px solid rgba(77, 210, 255, 0.24);
  background: rgba(77, 210, 255, 0.12);
}
</style>
