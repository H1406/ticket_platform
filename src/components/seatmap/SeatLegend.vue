<template>
  <div class="d-flex flex-wrap gap-3">
    <div class="badge-soft"><span class="seat-dot bg-info"></span> Available</div>
    <div class="badge-soft"><span class="seat-dot bg-success"></span> Your hold</div>
    <div class="badge-soft"><span class="seat-dot bg-warning"></span> Held</div>
    <div class="badge-soft"><span class="seat-dot bg-danger"></span> Booked</div>
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
