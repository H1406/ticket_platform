import { mockBookingHistory, mockTicket } from '../../shared/mock/transitData.js'

export function listBookingHistory(_req, res) {
  res.json({
    items: mockBookingHistory
  })
}

export function createBooking(req, res) {
  const payload = req.body || {}

  res.status(201).json({
    id: `BK-${Date.now()}`,
    status: 'pending-confirmation',
    ticketPreview: mockTicket,
    payload
  })
}
