import { Router } from 'express'
import authRoutes from './auth.routes.js'
import bookingsRoutes from './bookings.routes.js'
import dashboardRoutes from './dashboard.routes.js'
import healthRoutes from './health.routes.js'
import transitRoutes from './transit.routes.js'

const router = Router()

router.use('/health', healthRoutes)
router.use('/auth', authRoutes)
router.use('/dashboard', dashboardRoutes)
router.use('/routes', transitRoutes)
router.use('/bookings', bookingsRoutes)

export default router
