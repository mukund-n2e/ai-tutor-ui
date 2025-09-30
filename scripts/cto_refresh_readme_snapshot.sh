#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

TEAM="${TEAM:-ai_tutor}"
PROJECT="${PROJECT:-tutor_web}"
PROD_URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"
BETA_DATE="${BETA_DATE:-22 Sep 2025}"
LLM_BUDGET="${LLM_BUDGET:-\$50/mo}"
CLOUD_BUDGET="${CLOUD_BUDGET:-\$100/mo}"

need(){ command -v "$1" >/dev/null 2>&1; }
die(){ echo "ERROR: $*" >&2; exit 2; }
need node || die "node not found"
need git  || die "git not found"

mkdir -p scripts
cat > scripts/docs_sync_refresh.mjs <<'JS'
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

const cwd = process.cwd();
const appDir = fs.existsSync(path.join(cwd,'web','package.json')) ? path.join(cwd,'web') : cwd;
const appAppDir = path.join(appDir,'src','app');

const TEAM = process.env.TEAM || 'ai_tutor';
const PROJECT = process.env.PROJECT || 'tutor_web';
const PROD_URL = process.env.PROD_URL || 'https://tutorweb-cyan.vercel.app';
const BETA_DATE = process.env.BETA_DATE || '22 Sep 2025';
const LLM_BUDGET = process.env.LLM_BUDGET || '$50/mo';
const CLOUD_BUDGET = process.env.CLOUD_BUDGET || '$100/mo';

function probe(url) {
  try { return execSync(`curl -s -o /dev/null -w "%{http_code}" "${url}" -H 'Cache-Control: no-cache'`, {stdio:['ignore','pipe','ignore']}).toString().trim(); } catch { return 'ERR'; }
}
function head(url) {
  try { return execSync(`curl -sI "${url}" | head -n1`, {stdio:['ignore','pipe','ignore']}).toString().trim(); } catch { return ''; }
}

const t = Date.now();
const ts = new Date().toISOString();
const health = probe(`${PROD_URL}/api/health`);
const smoke = probe(`${PROD_URL}/smoke?nocache=${t}`);
const courses = probe(`${PROD_URL}/courses?nocache=${t}`);
const tutor = probe(`${PROD_URL}/tutor?nocache=${t}`);
const sse = (head(`${PROD_URL}/api/tutor/stream`).match(/\s(\d{3})\s/) || [,''])[1] || '';

const START='<!-- AUTODOC: SNAPSHOT START -->';
const END='<!-- AUTODOC: SNAPSHOT END -->';

const readmePath = path.join(cwd,'README.md');
let readme = fs.existsSync(readmePath) ? fs.readFileSync(readmePath,'utf8') : '# Nudge2Edge — AI Tutor (Web)\n\n';

const snapshot = `${START}
### Project Snapshot (auto-updated)

- **Repo:** \`${path.basename(cwd)}\`
- **App root:** \`${path.relative(cwd, appAppDir)}\`
- **Stack:** Next.js 15 • Node ${process.version} • TypeScript
- **Team / Project (Vercel):** \`${TEAM}\` / \`${PROJECT}\`
- **Production:** ${PROD_URL}

**Routes (live check @ ${ts}):**
\`\`\`
GET /api/health           -> ${health}
GET /smoke                -> ${smoke}
GET /courses              -> ${courses}
GET /tutor                -> ${tutor}
GET /api/tutor/stream     -> ${sse}  (SSE endpoint)
\`\`\`

**Key Dates / Caps**
- **Public Beta:** ${BETA_DATE}
- **Budget caps:** LLM ${LLM_BUDGET} • Cloud ${CLOUD_BUDGET}

**Brand pipeline**
- Config: \`${path.relative(cwd, path.join(appDir,'brand/brand.config.json'))}\`
- Sync: \`node ${path.relative(cwd, path.join(appDir,'scripts/brand_sync.mjs'))}\` → writes \`${path.relative(cwd, path.join(appDir,'src/styles/tokens.css'))}\` + \`components.css\`
- Assets: \`${path.relative(cwd, path.join(appDir,'public/brand'))}/\`

${END}
`;

if (readme.includes(START)) {
  const pre = readme.split(START)[0];
  const post = readme.split(END)[1] || '';
  readme = pre + snapshot + post;
} else {
  readme += '\n' + snapshot + '\n';
}
fs.writeFileSync(readmePath, readme);

const docsDir = path.join(cwd,'docs'); fs.mkdirSync(docsDir,{recursive:true});
fs.writeFileSync(path.join(docsDir,'STATUS.md'),
`# Project Status — ${ts}

**Production:** ${PROD_URL}  
**Team/Project:** \`${TEAM}/${PROJECT}\`

## Live Checks
\`\`\`
GET /api/health       -> ${health}
GET /smoke            -> ${smoke}
GET /courses          -> ${courses}
GET /tutor            -> ${tutor}
SSE /api/tutor/stream -> ${sse}
\`\`\`
`);
JS

TEAM="$TEAM" PROJECT="$PROJECT" PROD_URL="$PROD_URL" \
BETA_DATE="$BETA_DATE" LLM_BUDGET="$LLM_BUDGET" CLOUD_BUDGET="$CLOUD_BUDGET" \
node scripts/docs_sync_refresh.mjs

TS="$(date -u +%Y%m%d_%H%M%S)"
BR="docs/snapshot-${TS}"
git config user.name  "mukund-n2e" >/dev/null
git config user.email "mukund-6019@users.noreply.github.com" >/dev/null
git switch -C "$BR" >/dev/null 2>&1 || git checkout -B "$BR"
git add README.md docs/STATUS.md 2>/dev/null || true
git commit -m "docs: refresh README snapshot (prod probes ${TS}Z)" >/dev/null 2>&1 || true
git push -u origin "$BR" >/dev/null 2>&1 || true

REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"; REMOTE="${REMOTE%.git}"
case "$REMOTE" in
  git@github.com:*) GH_URL="https://github.com/${REMOTE#git@github.com:}";;
  https://github.com/*) GH_URL="$REMOTE";;
  *) GH_URL="";;
esac

PR_URL=""
if command -v gh >/dev/null 2>&1; then
  PR_URL="$(gh pr create --head "$BR" --title "docs: refresh snapshot/status" --body "Auto-refreshed README snapshot and STATUS with current prod probe results.")" || true
fi

echo "=== CTO SNAPSHOT REFRESH SUMMARY START ==="
echo "Prod: $PROD_URL"
echo "Branch: $BR"
[ -n "$PR_URL" ] && echo "PR: $PR_URL" || [ -n "$GH_URL" ] && echo "Compare: $GH_URL/compare/$BR?expand=1"
echo "Files: README.md, docs/STATUS.md"
echo "=== CTO SNAPSHOT REFRESH SUMMARY END ==="



