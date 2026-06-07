<template>
  <div class="d-flex flex-wrap gap-3">
    <div class="badge-soft"><span class="seat-dot bg-info"></span> Available</div>
    <div class="badge-soft"><span class="seat-dot bg-success"></span> Selected</div>
    <div class="badge-soft"><span class="seat-dot bg-warning"></span> Reserved</div>
    <div class="badge-soft"><span class="seat-dot bg-danger"></span> Occupied</div>
  </div>
</template>

<style scoped>
.seat-dot {
  width: 10px;
  height: 10px;
  display: inline-block;
  border-radius: 999px;
}
</style>
