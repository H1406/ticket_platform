import { defineStore } from 'pinia'
import { supabase } from '@/services/supabase'

const demoProfile = {
  id: 'demo-user',
  firstName: 'Alex',
  lastName: 'Morgan',
  email: 'alex@transitflow.app',
  avatar: 'AM',
  isAdmin: true
}

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    profile: null,
    session: null,
    loading: false,
    initialized: false,
    error: ''
  }),
  getters: {
    isAuthenticated: (state) => Boolean(state.session),
    fullName: (state) =>
      state.profile ? `${state.profile.firstName} ${state.profile.lastName}` : 'Guest User'
  },
  actions: {
    async initialize() {
      this.loading = true

      try {
        const { data, error } = await supabase.auth.getSession()

        if (error) {
          throw error
        }

        this.session = data.session
        this.user = data.session?.user ?? null

        // TODO: Replace demo profile hydration with a Supabase profile query.
        this.profile = data.session ? demoProfile : null

        supabase.auth.onAuthStateChange((_event, session) => {
          this.session = session
          this.user = session?.user ?? null
          this.profile = session ? demoProfile : null
        })
      } catch (error) {
        this.error = error.message || 'Unable to initialize session'
      } finally {
        this.initialized = true
        this.loading = false
      }
    },
    async signInWithGoogle() {
      this.loading = true
      this.error = ''

      try {
        const { error } = await supabase.auth.signInWithOAuth({
          provider: 'google',
          options: {
            redirectTo: `${window.location.origin}/dashboard`
          }
        })

        if (error) {
          throw error
        }
      } catch (error) {
        this.error = error.message || 'Google sign-in failed'
      } finally {
        this.loading = false
      }
    },
    async signInWithPassword(payload) {
      this.loading = true
      this.error = ''

      try {
        const { data, error } = await supabase.auth.signInWithPassword(payload)

        if (error) {
          throw error
        }

        this.session = data.session
        this.user = data.user
        this.profile = demoProfile
      } catch (error) {
        this.error = error.message || 'Email sign-in failed'
      } finally {
        this.loading = false
      }
    },
    async signUp(payload) {
      this.loading = true
      this.error = ''

      try {
        const { error } = await supabase.auth.signUp(payload)

        if (error) {
          throw error
        }
      } catch (error) {
        this.error = error.message || 'Registration failed'
      } finally {
        this.loading = false
      }
    },
    async signOut() {
      this.loading = true

      try {
        await supabase.auth.signOut()
        this.user = null
        this.profile = null
        this.session = null
      } finally {
        this.loading = false
      }
    }
  }
})
