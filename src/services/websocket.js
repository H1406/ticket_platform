import { io } from 'socket.io-client'

let socket

export function initializeSocket() {
  if (socket) {
    return socket
  }

  socket = io(import.meta.env.VITE_SOCKET_URL || 'http://localhost:3001', {
    autoConnect: false,
    transports: ['websocket']
  })

  return socket
}

export const socketEvents = {
  seatsUpdated: 'seats:updated',
  bookingHoldCreated: 'booking:hold-created',
  bookingHoldExpired: 'booking:hold-expired',
  notificationsStream: 'notifications:stream',
  boardingUpdate: 'boarding:update'
}
