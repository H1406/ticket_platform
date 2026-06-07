<script setup>
import MainLayout from '@/layouts/MainLayout.vue'
</script>

<template>
  <MainLayout>
    <section class="page-section">
      <div class="container">
        <div class="glass-panel p-5 text-center">
          <h1 class="section-title mb-3">Page not found</h1>
          <p class="section-copy mx-auto mb-4">
            This route is not part of the current TransitFlow MVP scaffold.
          </p>
          <RouterLink to="/" class="btn btn-tf-primary">Return home</RouterLink>
        </div>
      </div>
    </section>
  </MainLayout>
</template>
