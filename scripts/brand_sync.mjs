import fs from 'fs'; import path from 'path';
const root = process.cwd();
const appDir = fs.existsSync(path.join(root,'web','package.json')) ? path.join(root,'web') : root;
const cfg = JSON.parse(fs.readFileSync(path.join(appDir,'brand','brand.config.json'),'utf8'));
const styDir = path.join(appDir,'src','styles'); fs.mkdirSync(styDir,{recursive:true});

const tokens = `:root{
  --bg:${cfg.light.bg};--fg:${cfg.light.fg};--muted:${cfg.light.muted};--border:${cfg.light.border};
  --card:${cfg.light.card};--accent:${cfg.light.accent};--accent-contrast:${cfg.light.accentContrast};
  --radius-1:${cfg.light.radius1};--radius-2:${cfg.light.radius2};--shadow-1:${cfg.light.shadow1};
  --font-sans:${cfg.typography.fontSans};
}
@media (prefers-color-scheme: dark){
  :root{
    --bg:${cfg.dark.bg};--fg:${cfg.dark.fg};--muted:${cfg.dark.muted};--border:${cfg.dark.border};
    --card:${cfg.dark.card};--accent:${cfg.dark.accent};--accent-contrast:${cfg.dark.accentContrast};
    --radius-1:${cfg.dark.radius1};--radius-2:${cfg.dark.radius2};--shadow-1:${cfg.dark.shadow1};
  }
}`;
fs.writeFileSync(path.join(styDir,'tokens.css'), tokens);

const comps = `:root{font-family:var(--font-sans);color:var(--fg);background:var(--bg);}
a{color:var(--accent);}
main.page{max-width:960px;margin:40px auto;padding:0 16px;}
.lead{color:var(--muted);margin:8px 0 16px;}
.grid-cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px;}
.card{background:var(--card);border:1px solid var(--border);border-radius:var(--radius-2);padding:16px;box-shadow:var(--shadow-1);}
.card .meta{font-size:14px;color:var(--muted);margin-bottom:8px;}
.topnav{display:flex;align-items:center;gap:16px;padding:12px 16px;border-bottom:1px solid var(--border);}
.brand{display:flex;align-items:center;gap:10px;font-weight:600;}
.brand img{display:block;height:${cfg.logo?.height ?? 24}px;}
`;
fs.writeFileSync(path.join(styDir,'components.css'), comps);

// Ensure layout.tsx exists and imports css (don't rewrite metadata)
const appAppDir = path.join(appDir,'src','app');
fs.mkdirSync(appAppDir, {recursive:true});
const layout = path.join(appAppDir,'layout.tsx');
if(!fs.existsSync(layout)){
  fs.writeFileSync(layout, `import '../styles/tokens.css';\nimport '../styles/components.css';\nexport default function RootLayout({children}:{children:React.ReactNode}){return <html><body>{children}</body></html>}`);
}else{
  let src = fs.readFileSync(layout,'utf8');
  if(!src.includes("src/styles/tokens.css")) src = `import '../styles/tokens.css';\n` + src;
  if(!src.includes("src/styles/components.css")) src = `import '../styles/components.css';\n` + src;
  fs.writeFileSync(layout, src);
}
console.log('brand_sync: wrote tokens.css/components.css and ensured layout imports.');
