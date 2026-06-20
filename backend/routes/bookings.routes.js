import { Router } from 'express'
import { createBooking, listBookingHistory } from '../controllers/bookings.controller.js'
import { getTicketById, listPassengerCheckins } from '../controllers/tickets.controller.js'

const router = Router()

router.get('/', listBookingHistory)
router.post('/', createBooking)
router.get('/checkins', listPassengerCheckins)
router.get('/tickets/:ticketId', getTicketById)

export default router
