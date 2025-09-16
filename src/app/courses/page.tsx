import Link from 'next/link';
import { listCourses } from '../../courses/registry';
export const metadata = { title: 'Courses' };
export default function CoursesPage() {
  const items = listCourses();
  return (
    <main style={{maxWidth: 960, margin: '40px auto', padding: '0 16px'}}>
      <h1 style={{marginBottom: 16}}>Courses</h1>
      <p style={{opacity: 0.8, marginBottom: 24}}>Structured paths to ship faster. Zero LLM spend on these pages.</p>
      <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 16}}>
        {items.map(c => (
          <article key={c.slug} style={{border: '1px solid #e5e7eb', borderRadius: 8, padding: 16}}>
            <h2 style={{marginTop: 0, marginBottom: 8}}>{c.title}</h2>
            <p style={{marginTop: 0, marginBottom: 8, opacity: 0.9}}>{c.description}</p>
            <div style={{fontSize: 14, opacity: 0.8, marginBottom: 12}}>
              {c.level ?? 'Unrated'} • ~{c.estMinutes ?? 20} min • {c.lessonsCount} lessons
            </div>
            <Link href={`/courses/${c.slug}`}>Open course →</Link>
          </article>
        ))}
      </div>
    </main>
  );
}
