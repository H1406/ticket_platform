<script setup>
import { computed } from 'vue'

const props = defineProps({
  status: {
    type: String,
    default: ''
  },
  expired: {
    type: Boolean,
    default: false
  }
})

const statusMeta = computed(() => {
  if (props.expired && props.status !== 'checked_in') {
    return {
      label: 'Expired',
      tone: 'expired',
      hint: 'Departure has passed'
    }
  }

  return {
    checked_in: {
      label: 'Checked in',
      tone: 'checked',
      hint: 'Boarding verified'
    },
    not_boarded: {
      label: 'Not boarded',
      tone: 'pending',
      hint: 'Ready for gate check-in'
    }
  }[props.status] || {
    label: props.status ? props.status.replace(/_/g, ' ') : 'Not boarded',
    tone: 'neutral',
    hint: 'Ticket status'
  }
})
</script>

<template>
  <span class="ticket-status" :class="`ticket-status--${statusMeta.tone}`" :title="statusMeta.hint">
    <span class="ticket-status__dot" aria-hidden="true"></span>
    <span class="ticket-status__label">{{ statusMeta.label }}</span>
  </span>
</template>

<style scoped>
.ticket-status {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  min-height: 32px;
  padding: 0.4rem 0.68rem;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 999px;
  color: var(--tf-text-muted);
  background: rgba(255, 255, 255, 0.06);
  font-size: 0.82rem;
  font-weight: 700;
  text-transform: capitalize;
  white-space: nowrap;
}

.ticket-status__dot {
  width: 0.55rem;
  height: 0.55rem;
  flex: 0 0 0.55rem;
  border-radius: 999px;
  background: currentColor;
  box-shadow: 0 0 0 4px color-mix(in srgb, currentColor 16%, transparent);
}

.ticket-status--checked {
  border-color: rgba(57, 217, 138, 0.28);
  color: #7ef9c6;
  background: rgba(57, 217, 138, 0.11);
}

.ticket-status--pending {
  border-color: rgba(77, 210, 255, 0.26);
  color: #9be8ff;
  background: rgba(77, 210, 255, 0.1);
}

.ticket-status--expired {
  border-color: rgba(255, 107, 122, 0.28);
  color: #ff9ca7;
  background: rgba(255, 107, 122, 0.1);
}
</style>
