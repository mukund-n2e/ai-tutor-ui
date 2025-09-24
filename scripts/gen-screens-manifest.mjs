import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.cwd();
const screensDir = path.join(ROOT, 'public', 'design', 'screens');
const outFile = path.join(ROOT, 'src', 'data', 'screens.json');

const files = fs.readdirSync(screensDir)
  .filter(f => /\.(png|jpe?g|webp|gif)$/i.test(f))
  .sort((a, b) => a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' }));

// Generate objects compatible with the Screens pages
const records = files.map((f, idx) => {
  const base = f.replace(/\.[^.]+$/, '');
  const slug = base.toLowerCase().replace(/[^a-z0-9-]+/g, '-');
  return {
    slug,
    title: base,
    file: f,
    order: idx + 1,
    route: `/wip/${slug}`,
    exists: false,
  };
});

fs.mkdirSync(path.dirname(outFile), { recursive: true });
fs.writeFileSync(outFile, JSON.stringify(records, null, 2));
console.log(`Generated ${outFile} with ${records.length} entries`);


