import { Router } from 'express'
import { getSeatMap, searchRoutes } from '../controllers/transit.controller.js'

const router = Router()

router.get('/search', searchRoutes)
router.get('/:routeId/seats', getSeatMap)

export default router
