import 'dotenv/config'

export const env = {
  port: Number(process.env.SERVER_PORT || 3001),
  clientOrigin: process.env.CLIENT_ORIGIN || 'http://localhost:5173'
}
