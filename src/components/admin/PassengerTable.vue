<script setup>
defineProps({
  passengers: Array,
  loading: Boolean,
  error: String
})
</script>

<template>
  <div class="glass-panel p-4 h-auto">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h3 class="h5 mb-0">Passenger check-in live feed</h3>
      <span class="text-muted-soft small">{{ passengers.length }} recent scans</span>
    </div>
    <div v-if="loading" class="text-muted-soft small py-4">
      Loading passenger check-ins...
    </div>
    <div v-else-if="error" class="text-danger small py-4">
      {{ error }}
    </div>
    <div class="table-responsive">
      <table v-if="!loading && !error" class="table table-dark table-borderless align-middle mb-0">
        <thead>
          <tr class="text-muted-soft">
            <th>Ticket</th>
            <th>Name</th>
            <th>Route</th>
            <th>Seat</th>
            <th>Gate</th>
            <th>Status</th>
            <th>Checked in</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="row in passengers" :key="row.id">
            <td class="text-truncate" style="max-width: 140px;" :title="row.ticketId">{{ row.ticketId }}</td>
            <td>{{ row.name }}</td>
            <td>{{ row.route }}</td>
            <td>{{ row.seat }}</td>
            <td>{{ row.gate }}</td>
            <td><span class="badge-soft">{{ row.status }}</span></td>
            <td>{{ row.checkedInAt ? new Date(row.checkedInAt).toLocaleString() : '-' }}</td>
          </tr>
          <tr v-if="!passengers.length">
            <td colspan="7" class="text-muted-soft text-center py-4">
              No passenger check-ins yet.
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
