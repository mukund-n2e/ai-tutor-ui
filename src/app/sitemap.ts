import type { MetadataRoute } from 'next';
import { listCourses } from '../courses/registry';

export const dynamic = 'force-static';

function canonBase() {
  // Prefer env if set; otherwise fall back to prod domain
  const base = process.env.NEXT_PUBLIC_BASE_URL || 'https://tutorweb-cyan.vercel.app';
  return base.replace(/\/+$/, ''); // no trailing slash
}
const u = (p: string) => `${canonBase()}${p}`;

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const items: MetadataRoute.Sitemap = [
    { url: u('/'), changeFrequency: 'weekly', priority: 0.7 },
    { url: u('/courses'), changeFrequency: 'weekly', priority: 0.7 },
    { url: u('/tutor'), changeFrequency: 'weekly', priority: 0.5 },
  ];

  try {
    const courses = listCourses();
    for (const c of courses) {
      items.push({ url: u(`/courses/${c.slug}`), changeFrequency: 'monthly', priority: 0.5 });
    }
  } catch {
    // If registry fails at build time, we still return the static entries above.
  }

  return items;
}
