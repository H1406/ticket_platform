<script setup>
const navItems = [
  { label: 'Overview', to: { name: 'admin' } },
  { label: 'Tickets & Check-in', to: { name: 'admin-tickets' } },
  { label: 'Passengers', to: null },
  { label: 'Routes', to: null },
  { label: 'Notifications', to: null }
]
</script>

<template>
  <aside class="glass-panel-strong p-4 h-auto">
    <div class="d-flex align-items-center gap-2 mb-4">
      <span class="d-inline-flex align-items-center justify-content-center rounded-circle bg-info-subtle text-dark" style="width: 42px; height: 42px;">TF</span>
      <div>
        <div class="fw-semibold">TransitFlow</div>
        <div class="text-muted-soft small">Operations console</div>
      </div>
    </div>

    <div class="d-flex flex-column gap-2">
      <template v-for="item in navItems" :key="item.label">
        <router-link
          v-if="item.to"
          :to="item.to"
          class="btn btn-tf-secondary text-start"
          active-class="btn-tf-primary"
        >
          {{ item.label }}
        </router-link>
        <button v-else class="btn btn-tf-secondary text-start" disabled>
          {{ item.label }}
        </button>
      </template>
    </div>

    <div class="glass-panel p-3 mt-4">
      <div class="small text-muted-soft mb-2">Realtime sync</div>
      <div class="fw-semibold">Socket + Supabase events ready</div>
    </div>
  </aside>
</template>
