import axios from 'axios'
import { supabase } from './supabase'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  timeout: 10000
})

apiClient.interceptors.request.use(async (config) => {
  const {
    data: { session }
  } = await supabase.auth.getSession()

  if (session?.access_token) {
    config.headers.Authorization = `Bearer ${session.access_token}`
  }

  return config
})

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    // Backend retry and token refresh policies belong here when those APIs go live.
    return Promise.reject(error)
  }
)

export const bookingApi = {
  searchRoutes(params) {
    return apiClient.get('/routes/search', { params })
  },
  fetchSeatMap(routeId) {
    return apiClient.get(`/routes/${routeId}/seats`)
  },
  createBooking(payload) {
    return apiClient.post('/bookings', payload)
  },
  fetchTicket(ticketId) {
    return apiClient.get(`/tickets/${ticketId}`)
  }
}

export const assistantApi = {
  sendMessage(payload) {
    return apiClient.post('/assistant', payload, {
      timeout: Number(import.meta.env.VITE_ASSISTANT_TIMEOUT_MS || 60000)
    })
  }
}

export default apiClient
