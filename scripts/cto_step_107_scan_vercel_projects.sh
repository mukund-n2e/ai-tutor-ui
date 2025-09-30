#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"

# Work from repo root
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

# Load token (env or file) and build CLI arg
TOKEN="${VERCEL_TOKEN:-}"
if [ -z "$TOKEN" ] && [ -f "$HOME/.vercel_token" ]; then
  TOKEN="$(cat "$HOME/.vercel_token" 2>/dev/null || true)"
fi
TOK_ARG=""
if [ -n "$TOKEN" ]; then
  TOK_ARG="--token $TOKEN"
fi

# Ensure context (no-op if already linked)
vercel link --project "$PROJECT" --yes --scope "$TEAM" $TOK_ARG >/dev/null || true

OUT_JSON="/tmp/_v_projects.json"
OUT_TXT="/tmp/_v_scan.txt"

# Try JSON first
if vercel projects ls --scope "$TEAM" --json $TOK_ARG > "$OUT_JSON" 2>/dev/null; then
  node -e '
    const fs = require("fs");
    const raw = fs.readFileSync(process.argv[1], "utf8").trim();
    let names = [];
    if (raw) {
      const lines = raw.split(/\r?\n/).filter(Boolean);
      if (lines.length > 1) {
        for (const line of lines) {
          try {
            const o = JSON.parse(line);
            if (o && Array.isArray(o.projects)) {
              names.push(...o.projects.map(p => p && p.name).filter(Boolean));
            } else if (o && o.name) {
              names.push(o.name);
            }
          } catch {}
        }
      } else {
        try {
          const j = JSON.parse(raw);
          if (Array.isArray(j)) {
            names = j.map(p => p && p.name).filter(Boolean);
          } else if (j && Array.isArray(j.projects)) {
            names = j.projects.map(p => p && p.name).filter(Boolean);
          } else if (j && j.name) {
            names = [j.name];
          }
        } catch {}
      }
    }
    names = Array.from(new Set(names)).sort();
    const stray = names.filter(n => n !== "ai-tutor-web");
    console.log("FOUND_PROJECTS=" + (names.join(",") || "none"));
    console.log("STRAY_PROJECTS=" + (stray.join(",") || "none"));
    console.log("STRAY_COUNT=" + stray.length);
  ' "$OUT_JSON" | tee "$OUT_TXT"
else
  # Fallback to table parse if no creds / JSON not available
  if vercel projects ls --scope "$TEAM" $TOK_ARG > /tmp/_v_projects_table.txt 2>/dev/null; then
    awk 'NR>1 && NF{print $1}' /tmp/_v_projects_table.txt | sort -u >/tmp/_v_names.txt
    ALL="$(paste -sd, /tmp/_v_names.txt)"
    STRAY="$(grep -v '^ai-tutor-web$' /tmp/_v_names.txt | paste -sd, -)"
    [ -n "$STRAY" ] || STRAY="none"
    printf "FOUND_PROJECTS=%s\nSTRAY_PROJECTS=%s\n" "${ALL:-none}" "$STRAY" | tee "$OUT_TXT"
    awk -v s="$STRAY" 'BEGIN{n=0; split(s,a,","); for(i in a) if(a[i]!="none" && a[i]!="") n++; print "STRAY_COUNT=" n;}'
  else
    echo "FOUND_PROJECTS=unknown"
    echo "STRAY_PROJECTS=unknown"
    echo "STRAY_COUNT=unknown"
  fi
fi


