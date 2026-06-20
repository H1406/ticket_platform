import { mockRoutes, mockSeatMap } from '../../shared/mock/transitData.js'

export function searchRoutes(req, res) {
  const { departure = '', destination = '', type = '' } = req.query

  const normalizedDeparture = String(departure).toLowerCase()
  const normalizedDestination = String(destination).toLowerCase()
  const normalizedType = String(type).toLowerCase()

  const items = mockRoutes.filter((route) => {
    const matchesDeparture =
      !normalizedDeparture || route.departure.toLowerCase().includes(normalizedDeparture)
    const matchesDestination =
      !normalizedDestination || route.destination.toLowerCase().includes(normalizedDestination)
    const matchesType = !normalizedType || route.type.toLowerCase() === normalizedType

    return matchesDeparture && matchesDestination && matchesType
  })

  res.json({ items })
}

export function getSeatMap(req, res) {
  res.json({
    routeId: req.params.routeId,
    items: mockSeatMap
  })
}
