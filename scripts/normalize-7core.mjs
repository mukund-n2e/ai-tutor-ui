import fs from 'fs'; import path from 'path';
const root = process.cwd();
const DESIGN = path.join(root, 'design', 'frames');
const GOLDEN_DIR = path.join(root, 'tests','screens','__screenshots__','screen.spec.ts');
const REQUIRED = ['landing','onboarding','wall','outline','pricing-AU','pricing-IN','pricing-ROW'];
const BP_MAP = { 'mobile':360, 'tablet':768, 'desktop':1200 };
const BP_FROM_NUM = { 360:'mobile', 768:'tablet', 1200:'desktop' };
const ALIASES = new Map([ ['home','landing'], ['index','landing'], ['lesson-outline','outline'], ['outline-l1-05','outline'], ['au','pricing-AU'], ['in','pricing-IN'], ['inr','pricing-IN'], ['row','pricing-ROW'], ['usd','pricing-ROW'] ]);
function walk(dir){ const out=[]; if(!fs.existsSync(dir)) return out; const st=[dir]; while(st.length){ const d=st.pop(); for(const e of fs.readdirSync(d,{withFileTypes:true})){ const p=path.join(d,e.name); e.isDirectory()? st.push(p): out.push(p);} } return out; }
function normalizeBase(base){ return base.toLowerCase().replace(/\s+/g,'-').replace(/_/g,'-'); }
function keyFromTokens(tokens){
  // exact
  for(const k of REQUIRED){ if(tokens.includes(k.toLowerCase())) return k; }
  // pricing variants
  if(tokens.includes('pricing')){ if(tokens.includes('au')) return 'pricing-AU'; if(tokens.includes('in')||tokens.includes('inr')) return 'pricing-IN'; if(tokens.includes('row')||tokens.includes('usd')||tokens.includes('global')) return 'pricing-ROW'; }
  // aliases
  for(const t of tokens){ if(ALIASES.has(t)) return ALIASES.get(t); }
  // outline heuristics
  if(tokens.includes('outline')) return 'outline';
  return null;
}
function bpFromBase(base){
  // numeric
  const m = base.match(/(\d{3,4})\b/);
  if(m){ const n = parseInt(m[1],10); if(BP_FROM_NUM[n]) return n; }
  // named
  if(base.includes('desktop')) return 1200;
  if(base.includes('tablet')) return 768;
  if(base.includes('mobile') || base.includes('phone')) return 360;
  return null;
}
const files = walk(DESIGN).filter(f=>f.toLowerCase().endsWith('.png'));
const placed = []; const missing = [];
fs.mkdirSync(GOLDEN_DIR,{recursive:true});
for(const key of REQUIRED){ for(const bp of [360,768,1200]){
  // already present? skip (idempotent)
  const dst = path.join(GOLDEN_DIR, `${key}--${BP_FROM_NUM[bp]}.png`);
  if(fs.existsSync(dst)) continue;
  // seek candidate
  let chosen=null;
  for(const f of files){
    const base = normalizeBase(path.basename(f,'.png'));
    const tokens = base.split(/[-.]+/g).filter(Boolean);
    const k = keyFromTokens(tokens);
    if(k !== key) continue;
    const got = bpFromBase(base);
    if(got===bp){ chosen=f; break; }
  }
  if(chosen){ fs.copyFileSync(chosen, dst); placed.push({key,bp,from:chosen,to:dst}); }
  else { missing.push({key,bp}); }
} }
const missingByKey = REQUIRED.map(k=>({ key:k, needs:[360,768,1200].filter(bp=>!fs.existsSync(path.join(GOLDEN_DIR, `${k}--${BP_FROM_NUM[bp]}.png`))) }));
const report = [];
report.push('# Missing goldens (7 cores × 3 viewports)');
let totalMissing = 0;
for(const row of missingByKey){ if(row.needs.length){ totalMissing += row.needs.length; report.push(`- **${row.key}** → missing: ${row.needs.join(', ')}`);} }
if(totalMissing===0) report.push('- None. ✅ All 21 goldens present.');
const out = path.join(root,'.pm','artifacts','missing-goldens.md');
fs.writeFileSync(out, report.join('\n'), 'utf8');
fs.writeFileSync(path.join(root,'.pm','artifacts','placed-goldens.json'), JSON.stringify(placed,null,2));
// Build screens.manifest.json
const manifest = {
  baseUrl: 'http://localhost:4321',
  viewports: { desktop: { width: 1200, height: 900 }, tablet: { width: 768, height: 1024 }, mobile: { width: 360, height: 780 } },
  screens: [
    { key: 'landing', path: '/' },
    { key: 'onboarding', path: '/onboarding' },
    { key: 'wall', path: '/wall' },
    { key: 'outline', path: '/lesson/L1-05/outline' },
    { key: 'pricing-AU', path: '/pricing?mk=AU' },
    { key: 'pricing-IN', path: '/pricing?mk=IN' },
    { key: 'pricing-ROW', path: '/pricing?mk=ROW' }
  ]
};
fs.writeFileSync('screens.manifest.json', JSON.stringify(manifest,null,2));
console.log('Placed goldens:', placed.length);
console.log('Missing total:', totalMissing);
if(totalMissing>0){ process.exit(2); }
