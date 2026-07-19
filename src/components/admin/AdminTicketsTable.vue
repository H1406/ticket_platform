<script setup>
defineProps({
  tickets: Array
})
</script>

<template>
  <div class="glass-panel p-4">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h3 class="h5 mb-0">All tickets</h3>
      <span class="text-muted-soft small">{{ tickets.length }} shown</span>
    </div>
    <div class="table-responsive">
      <table class="table table-dark table-borderless align-middle mb-0">
        <thead>
          <tr class="text-muted-soft">
            <th>Ticket</th>
            <th>Passenger</th>
            <th>Route</th>
            <th>Seat</th>
            <th>Departure</th>
            <th>Boarding</th>
            <th>Expiry</th>
            <th>Last check-in</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="ticket in tickets" :key="ticket.id">
            <td class="text-truncate" style="max-width: 140px;" :title="ticket.id">{{ ticket.id }}</td>
            <td>{{ ticket.passenger }}</td>
            <td>{{ ticket.route }}</td>
            <td>{{ ticket.seat }}</td>
            <td>{{ ticket.departureDate }} {{ ticket.departureTime }}</td>
            <td><span class="badge-soft">{{ ticket.isCheckedIn ? 'Checked in' : 'Not boarded' }}</span></td>
            <td><span class="badge-soft">{{ ticket.isExpired ? 'Expired' : 'Valid' }}</span></td>
            <td>{{ ticket.checkedInAt ? new Date(ticket.checkedInAt).toLocaleString() : '—' }}</td>
          </tr>
          <tr v-if="!tickets.length">
            <td colspan="8" class="text-muted-soft text-center py-4">No tickets match the current filters.</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
