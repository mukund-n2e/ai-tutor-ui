import { asMarkdown } from '@/lib/export';
import { sanitizeFilenameFriendly } from '@/lib/strings';
import { describe, expect, it } from 'vitest';

describe('export.asMarkdown', () => {
  it('sanitizes filename and formats markdown', () => {
    const { filename, md } = asMarkdown({ title: 'A/b? c.md', body: 'Hello' });
    expect(filename).toBe('A_b_c_md.md');
    expect(md.startsWith('# A/b? c.md')).toBe(true);
    expect(md.trim().endsWith('Hello')).toBe(true);
  });
});

describe('sanitizeFilenameFriendly', () => {
  it('normalizes unicode punctuation and spaces to hyphens', () => {
    const s = sanitizeFilenameFriendly("Quick‑win’s   current—draft!!");
    expect(s).toBe('quick-wins-current-draft');
  });
});


