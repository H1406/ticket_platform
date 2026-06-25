import axios from 'axios'

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  timeout: 10000
})

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    // TODO: Centralize retry policies and auth token refresh when backend APIs go live.
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

export default apiClient
