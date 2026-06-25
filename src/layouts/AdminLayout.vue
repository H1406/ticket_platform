<script setup>
import AdminSidebar from '@/components/admin/AdminSidebar.vue'
</script>

<template>
  <div class="app-shell d-flex min-vh-100 flex-column">
    <div class="container-fluid flex-grow-1 py-3 py-lg-4">
      <div class="row g-4 align-items-start">
        <div class="col-12 col-xl-3 col-xxl-2 p-3">
          <AdminSidebar />
        </div>
        <div class="col-12 col-xl-9 col-xxl-10 p-3 p-lg-4">
          <slot />
        </div>
      </div>
    </div>
  </div>
</template>
