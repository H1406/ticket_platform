<script setup>
import { computed, reactive } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AuthLayout from '@/layouts/AuthLayout.vue'

const authStore = useAuthStore()
const route = useRoute()
const router = useRouter()

const form = reactive({
  email: '',
  password: ''
})

const validationError = computed(() => {
  if (!form.email || !form.password) {
    return 'Email and password are required.'
  }

  return ''
})

async function submit() {
  if (validationError.value) {
    return
  }

  const targetPath =
    typeof route.query.redirect === 'string' ? route.query.redirect : '/dashboard'

  await authStore.signInWithPassword({
    email: form.email,
    password: form.password
  })

  if (!authStore.error && authStore.isAuthenticated) {
    router.push(targetPath)
  }
}

function continueWithGoogle() {
  const targetPath =
    typeof route.query.redirect === 'string' ? route.query.redirect : '/dashboard'

  authStore.signInWithGoogle(targetPath)
}
</script>

<template>
  <AuthLayout>
    <div class="row justify-content-center">
      <div class="col-xl-10">
        <div class="row g-4 align-items-stretch">
          <div class="col-lg-6">
            <div class="glass-panel-strong p-4 p-lg-5 h-100">
              <span class="eyebrow mb-3">Secure Access</span>
              <h1 class="section-title mb-3">Enter the TransitFlow workspace</h1>
              <p class="section-copy mb-4">
                Supabase Auth powers email sessions and Google OAuth, while route guards protect dashboards and admin views.
              </p>
              <div class="glass-panel p-4">
                <div class="fw-semibold mb-2">Included in this scaffold</div>
                <div class="text-muted-soft small">Persistent sessions, Google login placeholder, Pinia auth store, and protected routes.</div>
              </div>
            </div>
          </div>

          <div class="col-lg-6">
            <div class="glass-panel p-4 p-lg-5 h-100">
              <button class="btn btn-tf-secondary w-100 mb-3" @click="continueWithGoogle">
                Continue with Google
              </button>

              <div class="text-center text-muted-soft small mb-3">or use email and password</div>

              <form class="d-flex flex-column gap-3" @submit.prevent="submit">
                <div>
                  <label class="form-label">Email</label>
                  <input v-model="form.email" type="email" class="form-control" placeholder="you@company.com" />
                </div>
                <div>
                  <label class="form-label">Password</label>
                  <input v-model="form.password" type="password" class="form-control" placeholder="Minimum 6 characters" />
                </div>
                <div v-if="validationError" class="text-warning small">{{ validationError }}</div>
                <div v-if="authStore.error" class="text-danger small">{{ authStore.error }}</div>
                <div v-if="authStore.notice" class="text-info small">{{ authStore.notice }}</div>

                <button class="btn btn-tf-primary w-100" :disabled="authStore.loading">
                  {{ authStore.loading ? 'Please wait...' : 'Sign In' }}
                </button>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
  </AuthLayout>
</template>
