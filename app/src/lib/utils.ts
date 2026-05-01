import { customAlphabet } from 'nanoid'

// URL-safe alphabet, no ambiguous chars (0/O, 1/l/I)
const nanoid = customAlphabet('23456789abcdefghjkmnpqrstuvwxyz', 6)

export function generateSlug(): string {
  return nanoid()
}

export function isValidUrl(url: string): boolean {
  try {
    const parsed = new URL(url)
    return parsed.protocol === 'http:' || parsed.protocol === 'https:'
  } catch {
    return false
  }
}

export function isValidSlug(slug: string): boolean {
  return /^[a-z0-9]{3,12}$/.test(slug)
}
