import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { getCourse, listCourses } from '../../../courses/registry';
type Params = { params: { slug: string } };
export async function generateStaticParams() { return listCourses().map(c => ({ slug: c.slug })); }
export function generateMetadata({ params }: Params): Metadata {
  const c = getCourse(params.slug); return c ? { title: `Course • ${c.title}` } : { title: 'Course' };
}
export default function CoursePage({ params }: Params) {
  const course = getCourse(params.slug);
  if (!course) return notFound();
  return (
    <main style={{maxWidth: 960, margin: '40px auto', padding: '0 16px'}}>
      <header style={{marginBottom: 24}}>
        <h1 style={{margin: 0}}>{course.title}</h1>
        <div style={{fontSize: 14, opacity: 0.8}}>
          {course.level ?? 'Unrated'} • ~{course.estMinutes ?? 20} min • {course.lessons.length} lessons
        </div>
        {course.description && <p style={{marginTop: 12}}>{course.description}</p>}
      </header>
      <ol style={{paddingLeft: 20}}>
        {course.lessons.map((l, i) => (
          <li key={l.slug} style={{marginBottom: 16}}>
            <h3 style={{marginBottom: 6}}>{i + 1}. {l.title}</h3>
            {l.summary && <p style={{marginTop: 0, opacity: 0.9}}>{l.summary}</p>}
            <section style={{borderLeft: '3px solid #e5e7eb', paddingLeft: 12}}>
              {l.content}
            </section>
            {l.durationMin && <div style={{fontSize: 12, opacity: 0.8, marginTop: 6}}>~{l.durationMin} min</div>}
          </li>
        ))}
      </ol>
    </main>
  );
}
