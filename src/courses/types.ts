import type { ReactNode } from 'react';
export type Lesson = { slug: string; title: string; durationMin?: number; summary?: string; content: ReactNode; };
export type Course = { slug: string; title: string; level?: 'Beginner'|'Intermediate'|'Advanced'; estMinutes?: number; description?: string; lessons: Lesson[]; };
