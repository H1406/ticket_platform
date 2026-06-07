<script setup>
import AdminSidebar from '@/components/admin/AdminSidebar.vue'
</script>

<template>
  <div class="app-shell">
    <div class="container-fluid">
      <div class="row min-vh-100">
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
