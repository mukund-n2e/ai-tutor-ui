import fs from 'fs';
import path from 'path';

const root = process.cwd();
const appDir = fs.existsSync(path.join(root,'web','package.json')) ? path.join(root,'web') : root;
const pack = process.env.PACK || '/Users/mt/n2e-AI-tutor/ai-tutor-design-pack-v5';
const outPublic = path.join(appDir, 'public', 'design', 'screens');
// Write manifest where the app imports it from: web/src/design/screens.manifest.ts
const outDesign = path.join(appDir, 'src', 'design');
const manifestPath = path.join(outDesign, 'screens.manifest.ts');

fs.mkdirSync(outPublic, { recursive: true });
fs.mkdirSync(outDesign, { recursive: true });

const exts = new Set(['.png','.jpg','.jpeg','.svg','.webp']);
function slugify(name) {
  return name
    .toLowerCase()
    .replace(/\.[^.]+$/, '')
    .replace(/[_\s]+/g,'-')
    .replace(/[^a-z0-9-]/g,'')
    .replace(/-+/g,'-')
    .replace(/^-|-$/g,'');
}
function titleFrom(name) {
  const base = name.replace(/\.[^.]+$/, '').replace(/[-_]+/g,' ').trim();
  return base.charAt(0).toUpperCase() + base.slice(1);
}

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(p);
    else {
      const ext = path.extname(entry.name).toLowerCase();
      if (exts.has(ext)) files.push(p);
    }
  }
}
const files = [];
walk(pack);

const seen = new Map();
const records = [];
for (const abs of files) {
  const base = path.basename(abs);
  let slug = slugify(base);
  if (!slug) continue;
  // dedupe slugs
  let s = slug, i = 2;
  while (seen.has(s)) { s = `${slug}-${i++}`; }
  seen.set(s, true);

  // route suggestion
  const map = {
    'home': '/',
    'landing': '/',
    'tutor':'/tutor',
    'chat':'/tutor',
    'courses':'/courses',
    'course-wall':'/courses',
    'getting-started':'/courses/getting-started',
    'sessions':'/sessions',
    'settings':'/settings',
    'ship':'/ship',
    'onboarding':'/onboarding'
  };
  let route = map[s] || map[slug] || `/wip/${s}`;

  // copy asset into public
  const dest = path.join(outPublic, base);
  fs.copyFileSync(abs, dest);

  records.push({
    slug: s,
    title: titleFrom(base),
    file: base,
    route
  });
}

// mark existence of app routes
function pageExists(route) {
  if (route === '/') return true;
  const rel = route.replace(/^\/+/,''); // remove leading slash
  const routeDir = path.join(appDir, 'src', 'app', rel);
  return fs.existsSync(path.join(routeDir, 'page.tsx'));
}
for (const r of records) r.exists = pageExists(r.route);

// write TS manifest
const ts = `export type Screen = { slug: string; title: string; file: string; route: string; exists: boolean };
export const screens: Screen[] = ${JSON.stringify(records, null, 2)};`;
fs.writeFileSync(manifestPath, ts, 'utf8');

console.log(JSON.stringify({ copied: records.length, manifest: path.relative(root, manifestPath) }));
