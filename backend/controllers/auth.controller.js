export function getAuthStatus(_req, res) {
  res.json({
    ok: true,
    provider: 'supabase',
    oauth: {
      google: 'configured-in-supabase-dashboard'
    }
  })
}
