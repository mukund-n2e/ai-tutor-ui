export const sanitizeFilename = (s: string) => s
  .replace(/[^A-Za-z0-9-_]+/g, '_')
  .replace(/^_+|_+$/g, '');

// Friendlier filename sanitizer for user-facing downloads
// - Lowercase
// - Normalize Unicode and strip diacritics
// - Remove quotes and punctuation
// - Convert whitespace and separators to hyphens
// - Collapse and trim hyphens
// Example: "Quick‑win’s current draft" -> "quick-wins-current-draft"
export const sanitizeFilenameFriendly = (input: string): string => {
  try {
    const lowered = String(input ?? '').toLowerCase();
    const normalized = lowered.normalize('NFKD').replace(/[\u0300-\u036f]/g, '');
    const withoutQuotes = normalized.replace(/["'’‘“”`]+/g, '');
    const separatorsToHyphen = withoutQuotes.replace(/[\s\p{Pd}_]+/gu, '-');
    const alnumHyphenOnly = separatorsToHyphen.replace(/[^a-z0-9-]+/g, '-');
    const collapsed = alnumHyphenOnly.replace(/-+/g, '-');
    const trimmed = collapsed.replace(/^-+|-+$/g, '');
    return trimmed || 'untitled';
  } catch {
    return 'untitled';
  }
};

export const words = (s: string) => s.trim().split(/\s+/).filter(Boolean);
export const stripHtmlAndUrls = (s: string) => s
  .replace(/<[^>]*>/g, '')
  .replace(/https?:\/\/\S+/g, '');


