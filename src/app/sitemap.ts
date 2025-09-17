import type { MetadataRoute } from 'next'

export default function sitemap(): MetadataRoute.Sitemap {
  const base = process.env.NEXT_PUBLIC_SITE_URL || 'https://tutorweb-cyan.vercel.app'
  const urls = ['/', '/tutor', '/courses', '/courses/getting-started']
  const now = new Date().toISOString()
  return urls.map((u) => ({ url: `${base}${u}`, lastModified: now }))
}


