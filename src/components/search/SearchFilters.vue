<script setup>
const model = defineModel({
  type: Object,
  required: true
})
</script>

<template>
  <div class="glass-panel p-4">
    <h3 class="h5 mb-3">Filters</h3>
    <div class="mb-3">
      <label class="form-label text-muted-soft">Price range</label>
      <input v-model="model.price" type="range" class="form-range" min="20" max="300" />
    </div>
    <div class="mb-3">
      <label class="form-label text-muted-soft">Transport type</label>
      <select v-model="model.type" class="form-select">
        <option value="">All</option>
        <option value="train">Train</option>
        <option value="flight">Flight</option>
      </select>
    </div>
    <div>
      <label class="form-label text-muted-soft">Departure time</label>
      <select v-model="model.time" class="form-select">
        <option value="">Any time</option>
        <option value="morning">Morning</option>
        <option value="afternoon">Afternoon</option>
        <option value="night">Night</option>
      </select>
    </div>
  </div>
</template>
