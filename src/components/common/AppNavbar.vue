<script setup>
import { computed } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const route = useRoute()
const router = useRouter()

const navItems = computed(() => [
  { label: 'Platform', to: '/' },
  { label: 'Dashboard', to: '/dashboard' },
  { label: 'Search', to: '/search' },
  { label: 'Seats', to: '/seat-selection' },
  { label: 'Ticket', to: '/ticket' }
])

async function handleSignOut() {
  await authStore.signOut()
  router.push('/')
}
</script>

<template>
  <nav class="navbar navbar-expand-lg navbar-dark py-3">
    <div class="container">
      <RouterLink class="navbar-brand d-flex align-items-center gap-2 fw-semibold" to="/">
        <span class="d-inline-flex align-items-center justify-content-center rounded-circle bg-info-subtle text-dark" style="width: 40px; height: 40px;">TF</span>
        TransitFlow
      </RouterLink>

      <button
        class="navbar-toggler border-0 shadow-none"
        type="button"
        data-bs-toggle="collapse"
        data-bs-target="#mainNav"
      >
        <span class="navbar-toggler-icon"></span>
      </button>

      <div id="mainNav" class="collapse navbar-collapse">
        <ul class="navbar-nav mx-auto gap-lg-2">
          <li v-for="item in navItems" :key="item.to" class="nav-item">
            <RouterLink
              :to="item.to"
              class="nav-link px-3 rounded-pill"
              :class="{ active: route.path === item.to }"
            >
              {{ item.label }}
            </RouterLink>
          </li>
        </ul>

        <div class="d-flex flex-column flex-lg-row gap-2">
          <RouterLink
            v-if="!authStore.isAuthenticated"
            to="/auth"
            class="btn btn-tf-primary"
          >
            Sign In
          </RouterLink>
          <template v-else>
            <RouterLink to="/admin" class="btn btn-tf-secondary">Admin</RouterLink>
            <button class="btn btn-tf-secondary" @click="handleSignOut">Logout</button>
          </template>
        </div>
      </div>
    </div>
  </nav>
</template>
