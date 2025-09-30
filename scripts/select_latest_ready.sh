#!/usr/bin/env bash
set -euo pipefail

VERCEL_TOKEN="${VERCEL_TOKEN:-}"
if [ -z "$VERCEL_TOKEN" ]; then
  VERCEL_TOKEN="$(cat ~/.vercel_token 2>/dev/null || true)"
fi
[ -n "$VERCEL_TOKEN" ] || { echo "set VERCEL_TOKEN" >&2; exit 2; }
TEAM="${TEAM:-ai-tutor-7f989507}"
PROJ="${PROJ:-ai-tutor-web}"

# Try JSON mode first; if unsupported, fall back to parsing the table output
if json_out="$(vercel list "$PROJ" --prod --scope "$TEAM" --token "$VERCEL_TOKEN" --json 2>/dev/null)"; then
  node -e '
let d="";process.stdin.on("data",c=>d+=c);process.stdin.on("end",()=>{
  const j=JSON.parse(d); const arr = Array.isArray(j)? j : (j.deployments||[]);
  const ready = arr.filter(x => ["READY","SUCCEEDED"].includes(String(x.readyState||x.state||"").toUpperCase()));
  ready.sort((a,b)=> Number(a.created||0)-Number(b.created||0));
  if(!ready.length){ console.error("No READY prod deployments"); process.exit(2); }
  process.stdout.write(String(ready[ready.length-1].url));
});' <<< "$json_out"
  exit 0
fi

# Fallback: parse the human table, pick newest Ready and strip scheme
CLEAN=$(vercel list "$PROJ" --prod --scope "$TEAM" --token "$VERCEL_TOKEN" 2>/dev/null | sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g')
BLOCK=$(printf '%s\n' "$CLEAN" | sed -n '/Production deployments/,/To display the next page/p')
# Prefer first Ready row from the table block
URL=$(printf '%s\n' "$BLOCK" | awk '/ Ready /{for(i=1;i<=NF;i++) if($i ~ /^https:\/\//){print $i; exit}}')
if [ -z "$URL" ]; then
  # Fallback: first https URL in entire output (may include errors)
  URL=$(printf '%s\n' "$CLEAN" | awk '/^https:\/\//{print; exit}')
fi
printf '%s\n' "$URL" | sed -E 's#^https?://##'


