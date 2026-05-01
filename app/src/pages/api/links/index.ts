import type { NextApiRequest, NextApiResponse } from 'next'
import { z } from 'zod'
import { prisma } from '@/lib/db'
import { generateSlug, isValidSlug } from '@/lib/utils'

const CreateLinkSchema = z.object({
  url: z.string().url({ message: 'Must be a valid URL including http:// or https://' }),
  slug: z.string().optional(),
  title: z.string().max(255).optional(),
})

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  const parsed = CreateLinkSchema.safeParse(req.body)
  if (!parsed.success) {
    return res.status(400).json({ error: parsed.error.errors[0].message })
  }

  const { url, title } = parsed.data
  let slug = parsed.data.slug

  // Validate custom slug if provided
  if (slug) {
    if (!isValidSlug(slug)) {
      return res.status(400).json({ error: 'Slug must be 3–12 lowercase alphanumeric characters' })
    }
    const existing = await prisma.link.findUnique({ where: { slug } })
    if (existing) {
      return res.status(409).json({ error: 'That slug is already taken' })
    }
  } else {
    // Generate a unique slug — retry up to 5 times on collision
    for (let i = 0; i < 5; i++) {
      const candidate = generateSlug()
      const existing = await prisma.link.findUnique({ where: { slug: candidate } })
      if (!existing) { slug = candidate; break }
    }
    if (!slug) return res.status(500).json({ error: 'Could not generate unique slug' })
  }

  const link = await prisma.link.create({
    data: { slug, url, title },
  })

  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL ?? `https://${req.headers.host}`

  return res.status(201).json({
    id: link.id,
    slug: link.slug,
    url: link.url,
    shortUrl: `${baseUrl}/${link.slug}`,
    createdAt: link.createdAt,
  })
}
