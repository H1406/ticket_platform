import { mockPassengerTable, mockTicket } from '../../shared/mock/transitData.js'

export function getTicketById(req, res) {
  res.json({
    ...mockTicket,
    id: req.params.ticketId || mockTicket.id
  })
}

export function listPassengerCheckins(_req, res) {
  res.json({
    items: mockPassengerTable
  })
}
