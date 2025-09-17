import type { Metadata } from 'next';
import dynamic from 'next/dynamic';
export const metadata: Metadata = { title: 'AI Tutor' };
const TutorShell = dynamic(() => import('../../components/TutorShell'), { ssr: true });
export default function Page() { return <TutorShell />; }
