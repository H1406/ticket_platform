import { Router } from 'express'

const router = Router()

router.post('/', (req, res) => {
  res.status(202).json({
    accepted: true,
    message: null,
    request: {
      message: req.body?.message || '',
      historyLength: Array.isArray(req.body?.history) ? req.body.history.length : 0
    }
  })
})

export default router
