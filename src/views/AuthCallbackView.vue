<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AuthLayout from '@/layouts/AuthLayout.vue'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const processing = ref(true)
const callbackError = ref('')

const nextPath = computed(() => {
  return typeof route.query.next === 'string' && route.query.next.startsWith('/')
    ? route.query.next
    : '/dashboard'
})

function getHashSessionParams() {
  const hash = window.location.hash.startsWith('#')
    ? window.location.hash.slice(1)
    : window.location.hash
  const params = new URLSearchParams(hash)

  return {
    accessToken: params.get('access_token') || '',
    refreshToken: params.get('refresh_token') || '',
    error: params.get('error_description') || params.get('error') || ''
  }
}

function clearUrlHash() {
  if (window.location.hash) {
    window.history.replaceState(null, '', `${window.location.pathname}${window.location.search}`)
  }
}

onMounted(async () => {
  const code = typeof route.query.code === 'string' ? route.query.code : ''
  const hashSession = getHashSessionParams()
  const providerError =
    hashSession.error ||
    (typeof route.query.error_description === 'string'
      ? route.query.error_description
      : typeof route.query.error === 'string'
        ? route.query.error
        : '')

  if (providerError) {
    clearUrlHash()
    callbackError.value = providerError
    processing.value = false
    return
  }

  try {
    if (code) {
      await authStore.handleOAuthCallback(code)
    } else if (hashSession.accessToken && hashSession.refreshToken) {
      await authStore.handleOAuthTokenCallback(hashSession)
      clearUrlHash()
    } else if (!authStore.initialized) {
      await authStore.initialize()
    }

    if (authStore.isAuthenticated) {
      await router.replace(nextPath.value)
      return
    }

    callbackError.value = 'No OAuth session was returned. Please try signing in again.'
  } catch (error) {
    callbackError.value = error.message || 'Unable to complete sign-in.'
  } finally {
    processing.value = false
  }
})

function returnToAuth() {
  router.replace({
    name: 'auth',
    query: nextPath.value !== '/dashboard' ? { redirect: nextPath.value } : undefined
  })
}
</script>

<template>
  <AuthLayout>
    <div class="row justify-content-center">
      <div class="col-lg-6 col-xl-5">
        <div class="glass-panel p-4 p-lg-5 text-center">
          <div v-if="processing">
            <div class="spinner-border text-info mb-4" role="status" aria-hidden="true"></div>
            <h1 class="h3 mb-3">Completing sign-in</h1>
            <p class="text-muted-soft mb-0">
              TransitFlow is finalizing your Supabase session and preparing your workspace.
            </p>
          </div>

          <div v-else>
            <h1 class="h3 mb-3">Sign-in needs attention</h1>
            <p class="text-danger mb-4">{{ callbackError || authStore.error }}</p>
            <button class="btn btn-tf-primary" @click="returnToAuth">Back to login</button>
          </div>
        </div>
      </div>
    </div>
  </AuthLayout>
</template>
