import { sanitizeFilename } from '@/lib/strings';

export function asMarkdown(input: { title: string; body: string }) {
  const title = (input.title ?? 'Untitled').toString().trim() || 'Untitled';
  const body = (input.body ?? '').toString().replace(/\r\n/g, '\n').trim();
  const safeTitle = sanitizeFilename(title) || 'Untitled';
  const md = `# ${title}\n\n${body}\n`;
  return { filename: `${safeTitle}.md`, md };
}


