import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..', '..');
const tokenJsonPath = path.join(repoRoot, 'ai-tutor-design-pack-v4', 'design', 'tokens', 'tokens.json');
const outCssPath = path.join(__dirname, '..', 'src', 'styles', 'tokens.css');

const toKebab = (s) => String(s).replace(/[^A-Za-z0-9]+/g, '-').replace(/^-+|-+$/g, '').toLowerCase();

function flatten(obj, prefix = [], out = {}) {
  if (obj && typeof obj === 'object' && 'value' in obj && Object.keys(obj).length >= 1) {
    const name = '--' + prefix.map(toKebab).join('-');
    out[name] = obj.value;
    return out;
  }
  if (obj && typeof obj === 'object') {
    for (const [k, v] of Object.entries(obj)) {
      if (k.startsWith('$')) continue; // skip metadata keys
      flatten(v, [...prefix, k], out);
    }
  }
  return out;
}

const main = async () => {
  const json = JSON.parse(await fs.readFile(tokenJsonPath, 'utf8'));
  const vars = flatten(json);
  const lines = [':root {'];
  for (const [k, v] of Object.entries(vars)) lines.push(`  ${k}: ${v};`);
  lines.push('}', '');
  await fs.writeFile(outCssPath, lines.join('\n'), 'utf8');
  console.log(`Wrote ${outCssPath} (${Object.keys(vars).length} tokens)`);
};

main().catch((e) => { console.error(e); process.exit(1); });
