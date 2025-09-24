import type { Course } from './types';
import GettingStarted from './samples/getting-started';

const creator: Course = {
  slug: 'creator',
  title: 'Creator Micro-Course',
  description: 'Ship a short-form creative output fast with Understand → Draft → Polish.',
  estMinutes: 20,
  lessons: [
    { slug: 'u', title: 'Understand', summary: 'Clarify constraints and success criteria.', content: 'Understand move overview.' },
    { slug: 'd', title: 'Draft', summary: 'Create a concise first draft.', content: 'Draft move overview.' },
    { slug: 'p', title: 'Polish', summary: 'Tighten and prepare to ship.', content: 'Polish move overview.' }
  ]
};

const consultant: Course = {
  slug: 'consultant',
  title: 'Consultant Micro-Course',
  description: 'Structure proposal and client-ready outputs via the 3-step loop.',
  estMinutes: 20,
  lessons: [
    { slug: 'u', title: 'Understand', content: 'Understand move overview.' },
    { slug: 'd', title: 'Draft', content: 'Draft move overview.' },
    { slug: 'p', title: 'Polish', content: 'Polish move overview.' }
  ]
};

export const courses: Course[] = [GettingStarted, creator, consultant];
export function listCourses() {
  return courses.map(c => ({ slug: c.slug, title: c.title, level: c.level, estMinutes: c.estMinutes, description: c.description, lessonsCount: c.lessons.length }));
}
export function getCourse(slug: string): Course | null {
  return courses.find(c => c.slug === slug) ?? null;
}
