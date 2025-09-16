import type { Course } from './types';
import GettingStarted from './samples/getting-started';
export const courses: Course[] = [GettingStarted];
export function listCourses() {
  return courses.map(c => ({ slug: c.slug, title: c.title, level: c.level, estMinutes: c.estMinutes, description: c.description, lessonsCount: c.lessons.length }));
}
export function getCourse(slug: string): Course | null {
  return courses.find(c => c.slug === slug) ?? null;
}
