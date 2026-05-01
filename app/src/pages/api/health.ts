import type { NextApiRequest, NextApiResponse } from 'next'
import { prisma } from '@/lib/db'

// Traffic Manager probes this endpoint every 30s.
// Returns 200 only when the DB is reachable — so TM fails over
// if the database connection is broken, not just the web server.

type HealthResponse = {
  status: 'ok' | 'degraded'
  db: 'connected' | 'unreachable'
  uptime: number
  timestamp: string
  region: string
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<HealthResponse>
) {
  const start = Date.now()

  let dbStatus: 'connected' | 'unreachable' = 'unreachable'

  try {
    await prisma.$queryRaw`SELECT 1`
    dbStatus = 'connected'
  } catch {
    // DB unreachable — return 503 so Traffic Manager fails over
    return res.status(503).json({
      status: 'degraded',
      db: 'unreachable',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      region: process.env.AZURE_REGION ?? 'unknown',
    })
  }

  res.status(200).json({
    status: 'ok',
    db: dbStatus,
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    region: process.env.AZURE_REGION ?? 'unknown',
  })
}
