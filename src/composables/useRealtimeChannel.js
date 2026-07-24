import { onBeforeUnmount, onMounted } from 'vue'
import { initializeSocket, socketEvents } from '@/services/websocket'

export function useRealtimeChannel(subscriptions = {}) {
  const socket = initializeSocket()
  const removers = []

  onMounted(() => {
    // Subscriptions are registered by the caller after the app initializes auth state.
    Object.entries(subscriptions).forEach(([eventName, handler]) => {
      socket.on(eventName, handler)
      removers.push(() => socket.off(eventName, handler))
    })
  })

  onBeforeUnmount(() => {
    removers.forEach((remove) => remove())
  })

  return {
    socket,
    socketEvents
  }
}
