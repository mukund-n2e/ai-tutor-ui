export const sanitizeFilename = (s: string) => s
  .replace(/[^A-Za-z0-9-_]+/g, '_')
  .replace(/^_+|_+$/g, '');

export const words = (s: string) => s.trim().split(/\s+/).filter(Boolean);
export const stripHtmlAndUrls = (s: string) => s
  .replace(/<[^>]*>/g, '')
  .replace(/https?:\/\/\S+/g, '');


