import cors from 'cors'
import express from 'express'
import routes from './routes/index.js'
import { env } from './config/env.js'

const app = express()

app.use(
  cors({
    origin: env.clientOrigin,
    credentials: true
  })
)
app.use(express.json())

app.get('/', (_req, res) => {
  res.json({
    service: 'TransitFlow API',
    version: '0.1.0',
    docs: {
      health: '/api/health',
      routes: '/api/routes/search',
      dashboard: '/api/dashboard/summary'
    }
  })
})

app.use('/api', routes)

app.use((req, res) => {
  res.status(404).json({
    message: `No backend route matched ${req.method} ${req.originalUrl}`
  })
})

export default app
