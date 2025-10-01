import fs from 'fs'; import path from 'path';
const root = process.cwd(); const join = path.join; const exists = p => fs.existsSync(p);
const SRC_APP = join(root,'src','app'); const STYLES = join(root,'src','styles'); const DESIGN = join(root,'design');
const DESIGN_SPECS = exists(join(DESIGN,'specs')) ? join(DESIGN,'specs') : (exists(join(DESIGN,'spec')) ? join(DESIGN,'spec') : null);
const DESIGN_FRAMES = join(DESIGN,'frames'); const BREAKPOINTS = [360,768,1200];
const ALIAS_PATH = join(root,'.pm','config','key-alias.json');
const alias = exists(ALIAS_PATH) ? JSON.parse(fs.readFileSync(ALIAS_PATH,'utf8')) : {};
const aliasKeys = new Set(Object.keys(alias));
const aliasOf = k => alias[k] || null;
const allAliasesOf = k => { const seen=new Set([k]); let cur=k; let hop=aliasOf(cur); while(hop && !seen.has(hop)){ seen.add(hop); cur=hop; hop=aliasOf(cur);} return Array.from(seen); };
function walk(dir){ const out=[]; if(!exists(dir)) return out; const st=[dir]; while(st.length){ const d=st.pop(); for(const e of fs.readdirSync(d,{withFileTypes:true})){ const p=join(d,e.name); if(e.isDirectory()) st.push(p); else out.push(p);} } return out; }
function routeToKey(route){ const parts = route.split('/').filter(Boolean); if(parts.length===0) return 'landing'; if(parts[0]==='legal'&&parts[1]==='privacy') return 'legal-privacy'; if(parts[0]==='legal'&&parts[1]==='terms') return 'legal-terms'; if(parts[0]==='checkout'&&parts[1]==='success') return 'checkout-success'; if(parts[0]==='checkout'&&parts[1]==='error') return 'checkout-error'; if(parts[0]==='lesson'&&parts.includes('outline')) return 'outline'; if(parts[0]==='not-found') return 'not-found-404'; if(parts[0]==='error') return 'error-500'; return parts[0]; }
function collectRoutes(){ const pages=[]; for(const p of walk(SRC_APP)){ if(path.basename(p)==='page.tsx'){ const dir=path.dirname(p); const relDir=path.relative(SRC_APP,dir); const route='/' + (relDir? relDir.split(path.sep).join('/') : ''); pages.push({file:p, route, key:routeToKey(route)}); } } if(exists(join(SRC_APP,'not-found.tsx'))) pages.push({file:join(SRC_APP,'not-found.tsx'),route:'/not-found',key:'not-found-404'}); if(exists(join(SRC_APP,'error.tsx'))) pages.push({file:join(SRC_APP,'error.tsx'),route:'/error',key:'error-500'}); return pages; }
function collectCssKeys(){ if(!exists(STYLES)) return new Set(); const files=fs.readdirSync(STYLES).filter(n=>n.endsWith('.css')); const keys=new Set(); for(const f of files){ let k=f.replace(/\.module\.css$/,'').replace(/\.css$/,''); keys.add(k);} return keys; }
function collectSpecKeys(){ const keys=new Set(); if(!DESIGN_SPECS) return keys; for(const n of fs.readdirSync(DESIGN_SPECS)){ if(!/\.(yml|yaml)$/i.test(n)) continue; keys.add(n.replace(/\.(yml|yaml)$/i,'')); } return keys; }
function collectDesignGoldens(){ const ignore=new Set(['frames','spec','specs','brand']); const folders=exists(DESIGN)? fs.readdirSync(DESIGN,{withFileTypes:true}).filter(d=>d.isDirectory() && !ignore.has(d.name)).map(d=>join(DESIGN,d.name)) : []; const out=new Map(); const add=(key,bp,file)=>{ if(!out.has(key)) out.set(key,{bps:new Set(),files:[]}); const e=out.get(key); e.bps.add(bp); e.files.push(file); }; for(const folder of folders){ const isSystem = path.basename(folder)==='system'; for(const p of walk(folder)){ if(!p.endsWith('.png')) continue; const name=path.basename(p,'.png'); const m=name.match(/^(.*?)-(\\d{3,4})$/); if(!m) continue; let key = isSystem? m[1] : m[1].split('-')[0]; const bp=parseInt(m[2],10); add(key,bp,p); } }
  // Propagate aliases: if we have goldens for V but access by K, duplicate
  for(const [k,v] of Object.entries(alias)){ if(out.has(v) && !out.has(k)) out.set(k, out.get(v)); }
  return out;
}
function rel(p){ return path.relative(root,p) || '.'; }
const routes = collectRoutes(); const cssKeys = collectCssKeys(); const specKeys = collectSpecKeys(); const goldens = collectDesignGoldens();
const cssForKey = (key)=>{ if(cssKeys.has(key)) return `${key}.module.css`; const systemish=/^(legal-|not-found|error|checkout-|account|success)/.test(key); if(systemish && cssKeys.has('system')) return 'system.module.css'; return null; };
const hasSpec = (key)=>{ const variants = allAliasesOf(key); return variants.some(k=>specKeys.has(k)); };
const hasGolden = (key)=>{ const variants = allAliasesOf(key); return variants.some(k=>goldens.has(k)); };
const goldenBps = (key)=>{ const variants = allAliasesOf(key); for(const k of variants){ if(goldens.has(k)) return Array.from(goldens.get(k).bps).sort((a,b)=>a-b); } return []; };
const routeKeys = new Map(); for(const r of routes){ if(!routeKeys.has(r.key)) routeKeys.set(r.key,{routes:new Set(), files:new Set()}); routeKeys.get(r.key).routes.add(r.route); routeKeys.get(r.key).files.add(r.file); }
const allKeys = new Set([ ...routeKeys.keys(), ...cssKeys, ...specKeys, ...goldens.keys(), 'pricing' ]);
const BREAKS = BREAKPOINTS; const rows=[]; const issues=[];
for(const key of allKeys){ const routesFor = routeKeys.get(key)?.routes || new Set(); const routeList = Array.from(routesFor).sort(); const css = cssForKey(key); const specOk = hasSpec(key); const goldenOk = hasGolden(key); const bps = goldenBps(key); const bpOk = goldenOk ? BREAKS.every(b=>bps.includes(b)) : false; const row = { key, routes: routeList.join(', ') || '-', css: css||'-', spec: specOk ? 'yes':'NO', goldens: goldenOk?'yes':'NO', breakpoints: goldenOk ? (bpOk? 'OK' : `missing:${BREAKS.filter(b=>!bps.includes(b)).join(',')}`) : '-' }; rows.push(row); if(routeList.length===0 || !css || !specOk || !goldenOk || (goldenOk && !bpOk)) issues.push(row); }
function scanFor(pattern, roots){ const hits=[]; for(const r of roots){ for(const f of walk(r)){ if(/node_modules|\.next|playwright-report|\.pm\//.test(f)) continue; const txt=fs.readFileSync(f,'utf8'); if(pattern.test(txt)) hits.push(f); } } return hits; }
const inlineStyleHits = scanFor(/style=\{\{/g, [join(root,'src','app'), join(root,'src','components')]);
const rawHexHits = scanFor(/#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b/g, [join(root,'src')]).filter(f=>!f.endsWith('tokens.css'));
const rgbaHits = scanFor(/rgba?\(/g, [join(root,'src')]).filter(f=>!f.endsWith('tokens.css'));
const report=[]; report.push('# Baseline Audit — AI Tutor UI (Aligned)'); report.push('');
report.push(`- src/app: ${exists(SRC_APP)?'present':'MISSING'}`); report.push(`- src/styles: ${exists(STYLES)?'present':'MISSING'}`); report.push(`- design/frames: ${exists(DESIGN_FRAMES)?'present':'MISSING'}`); report.push(`- design/specs|spec: ${DESIGN_SPECS? 'present':'MISSING'}`); report.push(''); report.push(`Breakpoints required: ${BREAKPOINTS.join(', ')}`); report.push('');
report.push('## Coverage Table (key → route → css → spec → goldens → breakpoints)'); report.push('| key | routes | css | spec | goldens | breakpoints |'); report.push('|---|---|---|:---:|:---:|---|');
for(const r of rows.sort((a,b)=>a.key.localeCompare(b.key))){ report.push(`| ${r.key} | ${r.routes} | ${r.css} | ${r.spec} | ${r.goldens} | ${r.breakpoints} |`); }
report.push(''); report.push(`## Gaps (${issues.length})`); if(issues.length){ for(const r of issues){ report.push(`- **${r.key}** → route: ${r.routes||'-'}, css: ${r.css}, spec: ${r.spec}, goldens: ${r.goldens}, breakpoints: ${r.breakpoints}`);} } else { report.push('- None. ✅'); }
report.push(''); report.push('## Hygiene checks'); report.push(`- Inline styles in app/components: ${inlineStyleHits.length? 'FOUND':'none'}`); report.push(`- Raw hex colors outside tokens.css: ${rawHexHits.length? 'FOUND':'none'}`); report.push(`- rgb/rgba outside tokens.css: ${rgbaHits.length? 'FOUND':'none'}`);
if(inlineStyleHits.length){ report.push('\n### Inline style hits'); for(const h of inlineStyleHits) report.push('- '+path.relative(root,h)); }
if(rawHexHits.length){ report.push('\n### Raw hex color hits'); for(const h of rawHexHits) report.push('- '+path.relative(root,h)); }
if(rgbaHits.length){ report.push('\n### rgb/rgba hits'); for(const h of rgbaHits) report.push('- '+path.relative(root,h)); }
const out = join(root,'.pm','artifacts','baseline','Baseline-Audit-02.md'); fs.writeFileSync(out, report.join('\n'),'utf8'); console.log(report.join('\n'));
if(issues.length || inlineStyleHits.length || rawHexHits.length || rgbaHits.length){ process.exitCode = 2; }