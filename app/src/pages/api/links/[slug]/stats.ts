import type { NextApiRequest, NextApiResponse } from 'next'
import { prisma } from '@/lib/db'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' })

  const { slug } = req.query as { slug: string }

  const link = await prisma.link.findUnique({
    where: { slug },
    include: {
      _count: { select: { clicks: true } },
      clicks: {
        orderBy: { clickedAt: 'desc' },
        take: 10,
        select: { clickedAt: true, referer: true, country: true, city: true },
      },
    },
  })

  if (!link) return res.status(404).json({ error: 'Link not found' })

  // Click count by day for the last 7 days
  const sevenDaysAgo = new Date()
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)

  const clicksByDay = await prisma.click.groupBy({
    by: ['clickedAt'],
    where: { linkId: link.id, clickedAt: { gte: sevenDaysAgo } },
    _count: { id: true },
  })

  return res.status(200).json({
    slug: link.slug,
    url: link.url,
    title: link.title,
    totalClicks: link._count.clicks,
    recentClicks: link.clicks,
    createdAt: link.createdAt,
    clicksByDay,
  })
}
