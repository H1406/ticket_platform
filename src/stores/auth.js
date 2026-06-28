import { defineStore } from 'pinia'
import { supabase } from '@/services/supabase'

let authSubscription = null

function sanitizeRedirectPath(path) {
  if (typeof path !== 'string' || !path.startsWith('/')) {
    return '/dashboard'
  }

  return path
}

function buildFallbackProfile(user) {
  const metadata = user?.user_metadata ?? {}
  const firstName = metadata.given_name || metadata.first_name || ''
  const lastName = metadata.family_name || metadata.last_name || ''
  const email = user?.email || ''

  return {
    id: user?.id || null,
    firstName,
    lastName,
    email,
    avatar: `${firstName[0] || email[0] || 'U'}${lastName[0] || ''}`.toUpperCase(),
    avatarUrl: metadata.avatar_url || '',
    role: 'user',
    isAdmin: false
  }
}

function normalizeProfile(profile, user) {
  const fallback = buildFallbackProfile(user)

  if (!profile) {
    return fallback
  }

  const firstName = profile.first_name || fallback.firstName
  const lastName = profile.last_name || fallback.lastName
  const email = profile.email || user?.email || fallback.email
  const role = profile.role || 'user'

  return {
    id: profile.id,
    firstName,
    lastName,
    email,
    avatar: `${firstName[0] || email[0] || 'U'}${lastName[0] || ''}`.toUpperCase(),
    avatarUrl: profile.avatar_url || fallback.avatarUrl,
    role,
    isAdmin: role === 'admin'
  }
}

async function upsertOwnProfile(user) {
  if (!user?.id) {
    return null
  }

  const metadata = user.user_metadata ?? {}
  const email = user.email || ''

  const payload = {
    id: user.id,
    email,
    first_name: metadata.given_name || metadata.first_name || null,
    last_name: metadata.family_name || metadata.last_name || null,
    avatar_url: metadata.avatar_url || null
  }

  const { data, error } = await supabase
    .from('profiles')
    .upsert(payload, { onConflict: 'id' })
    .select('id, email, first_name, last_name, avatar_url, role')
    .single()

  if (error) {
    throw error
  }

  return data
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
    fullName: (state) => {
      if (!state.profile) {
        return 'Guest User'
      }

      const fullName = `${state.profile.firstName} ${state.profile.lastName}`.trim()
      return fullName || state.profile.email || 'Guest User'
    }
  },
  actions: {
    async fetchProfile(userId) {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, email, first_name, last_name, avatar_url, role')
        .eq('id', userId)
        .maybeSingle()

      if (error) {
        throw error
      }

      return data
    },
    async applySession(session) {
      this.session = session
      this.user = session?.user ?? null

      if (!session?.user) {
        this.profile = null
        return
      }

      const {
        data: { user },
        error: userError
      } = await supabase.auth.getUser()

      if (userError) {
        throw userError
      }

      this.user = user

      try {
        let profile = await this.fetchProfile(user.id)

        if (!profile) {
          profile = await upsertOwnProfile(user)
        }

        this.profile = normalizeProfile(profile, user)
      } catch (error) {
        // TODO: Replace this fallback with a dedicated onboarding/profile completion flow.
        this.profile = buildFallbackProfile(user)
        this.error = error.message || 'Unable to load profile data'
      }
    },
    async initialize() {
      if (this.initialized) {
        return
      }

      this.loading = true
      this.error = ''

      try {
        const { data, error } = await supabase.auth.getSession()

        if (error) {
          throw error
        }

        await this.applySession(data.session)

        if (!authSubscription) {
          const { data: authListener } = supabase.auth.onAuthStateChange((_event, session) => {
            void this.applySession(session)
          })

          authSubscription = authListener.subscription
        }
      } catch (error) {
        this.error = error.message || 'Unable to initialize session'
      } finally {
        this.initialized = true
        this.loading = false
      }
    },
    async handleOAuthCallback(code) {
      this.loading = true
      this.error = ''

      try {
        const { data, error } = await supabase.auth.exchangeCodeForSession(code)

        if (error) {
          throw error
        }

        await this.applySession(data.session)
      } catch (error) {
        this.error = error.message || 'OAuth callback failed'
        throw error
      } finally {
        this.initialized = true
        this.loading = false
      }
    },
    async signInWithGoogle(targetPath = '/dashboard') {
      this.loading = true
      this.error = ''

      try {
        const nextPath = sanitizeRedirectPath(targetPath)
        const redirectTo = new URL('/callback', window.location.origin)

        redirectTo.searchParams.set('next', nextPath)

        const { error } = await supabase.auth.signInWithOAuth({
          provider: 'google',
          options: {
            redirectTo: redirectTo.toString()
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

        await this.applySession(data.session)
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
        const { data, error } = await supabase.auth.signUp(payload)

        if (error) {
          throw error
        }

        if (data.session) {
          await this.applySession(data.session)
        }
      } catch (error) {
        this.error = error.message || 'Registration failed'
      } finally {
        this.loading = false
      }
    },
    async signOut() {
      this.loading = true
      this.error = ''

      try {
        const { error } = await supabase.auth.signOut()

        if (error) {
          throw error
        }

        this.user = null
        this.profile = null
        this.session = null
      } catch (error) {
        this.error = error.message || 'Sign out failed'
      } finally {
        this.loading = false
      }
    }
  }
})
