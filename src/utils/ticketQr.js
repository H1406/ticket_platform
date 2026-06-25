import QRCode from 'qrcode'

export async function generateTicketQrAssets(ticketId) {
  const payload = String(ticketId)
  const options = {
    errorCorrectionLevel: 'M',
    margin: 1,
    width: 240
  }

  const [dataUrl, svg] = await Promise.all([
    QRCode.toDataURL(payload, options),
    QRCode.toString(payload, { ...options, type: 'svg' })
  ])

  return {
    payload,
    dataUrl,
    svg
  }
}
