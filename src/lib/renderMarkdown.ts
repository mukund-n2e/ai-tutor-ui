import { unified } from 'unified';
import remarkParse from 'remark-parse';
import remarkGfm from 'remark-gfm';
import remarkRehype from 'remark-rehype';
import rehypeSanitize from 'rehype-sanitize';
import rehypeStringify from 'rehype-stringify';

export async function safeMarkdown(md: string) {
  return String(
    await unified()
      .use(remarkParse)
      .use(remarkGfm)
      .use(remarkRehype)
      .use(rehypeSanitize, {
        tagNames: ['p','h1','h2','h3','ul','ol','li','strong','em','code','pre','blockquote','a','hr','span'],
        attributes: { a: ['href','title'], span: ['className'] },
        protocols: { href: ['https'] }
      })
      .use(rehypeStringify)
      .process(md)
  );
}


