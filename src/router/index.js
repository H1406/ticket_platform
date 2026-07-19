import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes = [
  {
    path: '/',
    name: 'landing',
    component: () => import('@/views/LandingView.vue'),
    meta: { layout: 'main' }
  },
  {
    path: '/auth',
    name: 'auth',
    component: () => import('@/views/AuthView.vue'),
    meta: { layout: 'auth', guestOnly: true }
  },
  {
    path: '/callback',
    name: 'auth-callback',
    component: () => import('@/views/AuthCallbackView.vue'),
    meta: { layout: 'auth' }
  },
  {
    path: '/dashboard',
    name: 'dashboard',
    component: () => import('@/views/DashboardView.vue'),
    meta: { layout: 'main', requiresAuth: true }
  },
  {
    path: '/search',
    name: 'search',
    component: () => import('@/views/SearchRoutesView.vue'),
    meta: { layout: 'main', requiresAuth: true }
  },
  {
    path: '/seat-selection',
    name: 'seat-selection',
    component: () => import('@/views/SeatSelectionView.vue'),
    meta: { layout: 'main', requiresAuth: true }
  },
  {
    path: '/ticket',
    name: 'ticket',
    component: () => import('@/views/TicketView.vue'),
    meta: { layout: 'main', requiresAuth: true }
  },
  {
    path: '/admin',
    name: 'admin',
    component: () => import('@/views/AdminDashboardView.vue'),
    meta: { layout: 'admin', requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/admin/tickets',
    name: 'admin-tickets',
    component: () => import('@/views/AdminTicketsView.vue'),
    meta: { layout: 'admin', requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/views/NotFoundView.vue'),
    meta: { layout: 'main' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior() {
    return { top: 0, behavior: 'smooth' }
  }
})

router.beforeEach(async (to) => {
  const authStore = useAuthStore()

  if (!authStore.initialized) {
    await authStore.initialize()
  }

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    return { name: 'auth', query: { redirect: to.fullPath } }
  }

  if (to.meta.guestOnly && authStore.isAuthenticated) {
    return { name: 'dashboard' }
  }

  if (to.meta.requiresAdmin && !authStore.profile?.isAdmin) {
    return { name: 'dashboard' }
  }
})

export default router
