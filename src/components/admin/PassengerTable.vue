<script setup>
defineProps({
  passengers: Array
})
</script>

<template>
  <div class="glass-panel p-4">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h3 class="h5 mb-0">Passenger check-in table</h3>
      <span class="text-muted-soft small">Mock live feed</span>
    </div>
    <div class="table-responsive">
      <table class="table table-dark table-borderless align-middle mb-0">
        <thead>
          <tr class="text-muted-soft">
            <th>ID</th>
            <th>Name</th>
            <th>Route</th>
            <th>Seat</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="row in passengers" :key="row.id">
            <td>{{ row.id }}</td>
            <td>{{ row.name }}</td>
            <td>{{ row.route }}</td>
            <td>{{ row.seat }}</td>
            <td><span class="badge-soft">{{ row.status }}</span></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
