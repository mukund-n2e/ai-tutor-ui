import fs from 'fs'; import path from 'path';
const root = process.cwd(); const join = path.join; const exists = p=>fs.existsSync(p);
const SRC_APP = join(root,'src','app'); const DESIGN = join(root,'design','frames');
const GOLDEN_OUT = join(root,'tests','screens','__screenshots__','screen.spec.ts');
const ALIAS_PATH = join(root,'.pm','config','key-alias.json');
const alias = exists(ALIAS_PATH)? JSON.parse(fs.readFileSync(ALIAS_PATH,'utf8')) : {};
const ignore = new Set(['system']);
if(!exists(DESIGN)) { console.error('design/frames/ not found'); process.exit(1); }
const folders = fs.readdirSync(DESIGN,{withFileTypes:true}).filter(d=>d.isDirectory() && !ignore.has(d.name)).map(d=>d.name);
const BREAKS = [360,768,1200]; const VP = {360:'mobile',768:'tablet',1200:'desktop'};
function walk(dir){ const out=[]; const st=[dir]; while(st.length){ const d=st.pop(); for(const e of fs.readdirSync(d,{withFileTypes:true})){ const p=join(d,e.name); e.isDirectory()? st.push(p) : out.push(p);} } return out; }
function findRouteForKey(key){
  for(const f of walk(SRC_APP)){ if(f.endsWith(path.sep+'page.tsx')){ const rel = path.relative(SRC_APP, path.dirname(f)); const segs = rel.split(path.sep).filter(Boolean); if(segs.includes(key)) return '/'+segs.join('/'); } }
  if(key==='outline'){ for(const f of walk(SRC_APP)){ if(f.endsWith(path.sep+'outline'+path.sep+'page.tsx')){ const rel = path.relative(SRC_APP, path.dirname(f)); return '/'+rel.split(path.sep).join('/'); } } }
  if(key==='landing'){ if(exists(join(SRC_APP,'page.tsx'))) return '/'; }
  return '/'+key;
}
function copyGolden(key){
  const candidates = [key, alias[key]].filter(Boolean);
  let copied = 0;
  for(const cand of candidates){
    const dir = join(DESIGN,cand); if(!exists(dir)) continue;
    for(const bp of BREAKS){ const src = join(dir, `${cand}-${bp}.png`); if(exists(src)){ const dst = join(GOLDEN_OUT, `${key}--${VP[bp]}.png`); fs.copyFileSync(src, dst); copied++; } }
  }
  return copied;
}
const screens = []; let totalCopied = 0;
for(const key of folders.sort()){ const route = findRouteForKey(key); const n = copyGolden(key); screens.push({ key, path: route }); totalCopied += n; }
const manifest = { baseUrl: 'http://localhost:4321', viewports: { desktop: { width: 1200, height: 900 }, tablet: { width: 768, height: 1024 }, mobile: { width: 360, height: 780 } }, screens };
fs.writeFileSync('screens.manifest.json', JSON.stringify(manifest,null,2));
console.log('Derived screens:', screens.map(s=>s.key).join(', '));
console.log('Goldens copied:', totalCopied);
if(totalCopied===0){ console.error('No goldens copied from design/. Check filenames like <key>-360.png'); process.exit(2); }
