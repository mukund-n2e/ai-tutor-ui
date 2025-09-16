import type { Metadata } from 'next';
import ChatSSE from '../../components/ChatSSE';

export const metadata: Metadata = { title: 'AI Tutor' };

export default function Page() {
  return <ChatSSE />;
}
