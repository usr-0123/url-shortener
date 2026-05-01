import type { GetServerSideProps } from 'next'
import { prisma } from '@/lib/db'

// This page only runs server-side — it never renders HTML.
// It records the click then immediately 301-redirects.

export const getServerSideProps: GetServerSideProps = async ({ params, req, res }) => {
  const slug = params?.slug as string

  const link = await prisma.link.findUnique({
    where: { slug, active: true },
  })

  if (!link) {
    return { notFound: true }
  }

  // Check expiry
  if (link.expiresAt && link.expiresAt < new Date()) {
    return { notFound: true }
  }

  // Record click asynchronously — don't block the redirect
  prisma.click.create({
    data: {
      linkId: link.id,
      referer: req.headers.referer ?? null,
      userAgent: req.headers['user-agent'] ?? null,
      // Country/city would come from Azure Front Door headers in production:
      country: (req.headers['x-azure-clientip'] as string) ?? null,
    },
  }).catch(() => {
    // Fire-and-forget — a click tracking failure must never break a redirect
  })

  return {
    redirect: {
      destination: link.url,
      permanent: false, // 302 so browsers don't cache; use 301 only for permanent links
    },
  }
}

// Required by Next.js — won't render since getServerSideProps redirects
export default function RedirectPage() {
  return null
}
