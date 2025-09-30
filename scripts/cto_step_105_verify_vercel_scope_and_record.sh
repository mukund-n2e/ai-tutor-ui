#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS="tutorweb-cyan.vercel.app"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

# Ensure context
vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null || true

# List projects (JSON), fall back to table if needed (tolerate no credentials)
SCAN_FILE=/tmp/_v_scan.txt
rm -f "$SCAN_FILE" 2>/dev/null || true
if vercel projects ls --scope "$TEAM" --json >/tmp/_v_projects.json 2>/dev/null; then
  node -e '
    const fs = require("fs");
    try {
      const a = JSON.parse(fs.readFileSync("/tmp/_v_projects.json","utf8"));
      const names = Array.isArray(a) ? a.map(p=>p.name).sort() : [];
      const stray = names.filter(n => n !== "ai-tutor-web");
      console.log("ALL_PROJECTS=" + names.join(","));
      console.log("STRAY=" + stray.join(","));
    } catch (e) {}
  ' >"$SCAN_FILE" || true
else
  # Fallback: parse table output if available
  if vercel projects ls --scope "$TEAM" >/tmp/_v_projects.txt 2>/dev/null; then
    awk 'NR>1 && NF{print $1}' /tmp/_v_projects.txt | sort | uniq >/tmp/_v_names.txt || true
    {
      echo -n "ALL_PROJECTS="
      paste -sd, /tmp/_v_names.txt 2>/dev/null || true
      echo -n "STRAY="
      (grep -v '^ai-tutor-web$' /tmp/_v_names.txt 2>/dev/null || true) | paste -sd, - 2>/dev/null || true
    } >"$SCAN_FILE"
  fi
fi

ALL="unknown"
STRAY="unknown"
if [ -f "$SCAN_FILE" ]; then
  ALL_TMP=$(grep '^ALL_PROJECTS=' "$SCAN_FILE" | cut -d= -f2- || true)
  STRAY_TMP=$(grep '^STRAY=' "$SCAN_FILE" | cut -d= -f2- || true)
  [ -n "${ALL_TMP:-}" ] && ALL="$ALL_TMP"
  [ -n "${STRAY_TMP:-}" ] && STRAY="$STRAY_TMP"
fi

STRAY_COUNT="unknown"
if [ "$STRAY" != "unknown" ] && [ -n "$STRAY" ] && [ "$STRAY" != "," ]; then
  STRAY_COUNT=$(awk -v s="$STRAY" 'BEGIN{n=0;split(s,a,","); for (i in a) if (a[i]!="") n++; print n;}' 2>/dev/null || echo "unknown")
fi

# Quick alias sanity
AON=$(curl -s -o /dev/null -w "%{http_code}" "https://${ALIAS}/onboarding")
ASE=$(curl -s -o /dev/null -w "%{http_code}" "https://${ALIAS}/session?verb=Create&persona=Creator&minutes=20&task=hello")
curl -sS -o /tmp/_alias.docx -X POST "https://${ALIAS}/api/export/docx" \
     -H 'Content-Type: application/json' \
     --data '{"title":"Status check","content":"Docx probe"}' || true
AHEX=$(hexdump -n 2 -e '2/1 "%02x"' /tmp/_alias.docx 2>/dev/null || echo "")

# Append a short note to docs/Status.md
mkdir -p docs
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
{
  echo "## Status ${TS}"
  echo "- Team: \`${TEAM}\`"
  echo "- Projects under team: ${ALL:-none}"
  echo "- Stray projects (expected 0): ${STRAY:-none} (count: ${STRAY_COUNT})"
  echo "- Alias: \`${ALIAS}\` → Onboarding:${AON} Session:${ASE} DOCX:${AHEX}"
  echo ""
} >> docs/Status.md

echo "STRAY_COUNT=${STRAY_COUNT}"
echo "ALIAS_ONBOARDING=${AON}"
echo "ALIAS_SESSION=${ASE}"
echo "ALIAS_DOCX_HEX=${AHEX}"
echo "STATUS_APPENDED=docs/Status.md"


