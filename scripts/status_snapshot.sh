#!/usr/bin/env bash
set -euo pipefail

# -------- Config (override via env) --------
REPO="${REPO:-mukund-n2e/ai-tutor-web}"                  # owner/repo for GitHub Actions
WORKFLOW_FILTER="${WORKFLOW_FILTER:-Promote Ready}"       # substring to match workflow name
TEAM_SLUG="${TEAM_SLUG:-ai-tutor-7f989507}"
PROJ="${PROJ:-ai-tutor-web}"
ALIAS="${ALIAS:-tutorweb-cyan.vercel.app}"               # current public alias
BASE_OVERRIDE="${BASE:-}"                                 # optional: set BASE to test a specific deployment domain
CANDIDATE_BASE="${BASE_OVERRIDE:-https://${ALIAS}}"

# Optional relaxations/allowlists
RELAXED_COPY="${RELAXED_COPY:-0}"
PRIMARY_CTA_ALLOWED="${PRIMARY_CTA_ALLOWED:-^/onboarding(/role)?([/?#]|$)}"
SECONDARY_CTA_ALLOWED="${SECONDARY_CTA_ALLOWED:-^/samples([/?#]|$)}"
ALLOW_SCREENS_REDIRECT="${ALLOW_SCREENS_REDIRECT:-0}"
ALLOW_MISSING_SECONDARY="${ALLOW_MISSING_SECONDARY:-0}"

# -------- Helpers --------
have() { command -v "$1" >/dev/null 2>&1; }
ok(){ printf '✅ %s\n' "$*"; }
warn(){ printf '⚠️  %s\n' "$*" >&2; }
fail(){ printf '❌ %s\n' "$*" >&2; exit 1; }
hdr(){ printf '\n===== %s =====\n' "$*"; }

# -------- Tooling checks --------
MISSING=0
have jq || { warn "jq not found; some JSON formatting disabled"; MISSING=1; }
have curl || fail "curl is required"
if ! have gh; then warn "gh (GitHub CLI) not found; will skip GitHub workflow section"; fi
if ! have vercel; then warn "vercel CLI not found; will not use CLI (API & curl checks still run)"; fi
if [[ -z "${VERCEL_TOKEN:-}" ]]; then
  if [[ -f "$HOME/.vercel_token" ]]; then
    export VERCEL_TOKEN="$(tr -d '\r\n"' < "$HOME/.vercel_token")"
  else
    warn "VERCEL_TOKEN not set; Vercel API sections will be limited"
  fi
fi

# -------- 1) GitHub Actions — what executed --------
if have gh && have jq; then
  hdr "GitHub Actions — last '${WORKFLOW_FILTER}' run summary"
  # Find the most recent run matching the workflow filter
  RUN_ID="$(
    gh run list --repo "$REPO" --limit 20 \
      --json databaseId,workflowName,headBranch,conclusion,status,createdAt \
      | jq -r --arg f "$WORKFLOW_FILTER" '
          .[] | select(.workflowName | test($f)) | .databaseId
        ' | head -n1
  )" || true

  if [[ -n "${RUN_ID:-}" ]]; then
    gh run view "$RUN_ID" --repo "$REPO" \
      --json status,conclusion,workflowName,displayTitle,headSha,updatedAt,jobs \
      | jq -r '
        .workflowName as $wf
        | "Workflow: \($wf)\nTitle: " + (.displayTitle // "-") +
          "\nSHA: " + (.headSha // "-") +
          "\nStatus: " + (.status // "-") +
          "\nConclusion: " + (.conclusion // "-") +
          "\nUpdated: " + (.updatedAt // "-") + "\n"
          + "\nJobs:"
          + ( .jobs | map(
                "\n  • " + .name
                + " → " + ((.conclusion // .status) // "-")
                + (if .steps then
                    "\n    Steps:"
                    + ( .steps | map("      - " + .name + " → " + ((.conclusion // .status) // "-")) | join("\n"))
                  else "" end)
            ) | join("") )
      '
    ok "Pulled job/step conclusions for run #$RUN_ID"
  else
    warn "No runs found matching workflow filter '$WORKFLOW_FILTER' in $REPO"
  fi
else
  hdr "GitHub Actions — skipped"
  echo "Install gh and jq (or set GITHUB_TOKEN for gh) to enable this section."
fi

# -------- 2) Runtime status — alias (or override BASE) --------
hdr "Runtime status — ${CANDIDATE_BASE}"
printf 'Probing key routes…\n'
routes=( / /onboarding/role /onboarding/readiness /onboarding/proposal /session /validator /export /screens )
for p in "${routes[@]}"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "${CANDIDATE_BASE}${p}")
  printf '  %-22s -> %s\n' "$p" "$code"
done

hdr "Landing copy & CTA hrefs"
body="$(curl -s "${CANDIDATE_BASE}/")"
if [[ "$RELAXED_COPY" != "1" ]]; then
  echo "$body" | grep -Fq "Learn and apply AI to your job. No fluff." || fail "Landing H1 mismatch"
  echo "$body" | grep -Fq "Pick a job task. We'll guide three decisive moves, validate, and you're done." || fail "Landing subtitle mismatch"
  echo "$body" | grep -Fq "Incognito by default. Nothing saved unless you say so." || fail "Footer copy mismatch"
else
  ok "RELAXED_COPY=1 (skipping exact copy match)"
fi

# Extract all anchor hrefs into one-per-line list
hrefs="$(printf '%s' "$body" | tr '\n' ' ' | perl -0777 -ne 'print "$1\n" while /<a[^>]*href=\"([^\"]+)\"/sig')"
printf '%s' "$hrefs" | grep -Eq "$PRIMARY_CTA_ALLOWED" || fail "Primary CTA not found matching: $PRIMARY_CTA_ALLOWED"
ok "Primary CTA allowed (pattern matched)"

if printf '%s' "$hrefs" | grep -Eq "$SECONDARY_CTA_ALLOWED"; then
  ok "Secondary CTA allowed (pattern matched)"
else
  if [[ "$ALLOW_MISSING_SECONDARY" == "1" ]]; then
    warn "Secondary CTA not found (allowed by ALLOW_MISSING_SECONDARY=1)"
  else
    fail "Secondary CTA not found matching: $SECONDARY_CTA_ALLOWED"
  fi
fi

hdr "SSR marker on /session"
sess="$(curl -s "${CANDIDATE_BASE}/session")"
echo "$sess" | grep -Fq 'data-ssr-moves="' || fail "SSR marker data-ssr-moves missing on /session"
ok "SSR marker present"

hdr "flags.json — headers & parse"
curl -sSI "${CANDIDATE_BASE}/flags.json" | awk 'BEGIN{IGNORECASE=1}/^HTTP\//||/content-type|cache-control|etag|content-encoding|age|server|vary/'
flags="$(curl -sS --compressed "${CANDIDATE_BASE}/flags.json")"
if have jq; then
  echo "$flags" | jq -e . >/dev/null || fail "flags.json is not valid JSON"
  echo "$flags" | jq -e '.beta == true' >/dev/null || fail "flags.beta != true"
else
  # Minimal check without jq
  echo "$flags" | grep -Fq '"beta":true' || fail "flags.beta != true (jq unavailable)"
fi
ok "flags.json valid (beta:true)"

hdr "/screens — count"
sc_code="$(curl -s -o /dev/null -w "%{http_code}" -L "${CANDIDATE_BASE}/screens")"
if [[ "$sc_code" == "200" ]]; then
  screens="$(curl -s "${CANDIDATE_BASE}/screens")"
  cnt=$(grep -o '/design/screens/' <<<"$screens" | wc -l | tr -d ' ')
  printf "count=%s\n" "$cnt"
  [[ "$cnt" -ge 1 ]] || fail "/screens shows zero cards"
  ok "/screens renders > 0 cards"
elif [[ "$ALLOW_SCREENS_REDIRECT" == "1" && "$sc_code" =~ ^30[1278]$ ]]; then
  ok "/screens -> $sc_code (allowed redirect)"
else
  fail "/screens -> $sc_code"
fi

hdr "SSE smoke (max 10s)"
start="$(curl -sS -X POST -H 'Content-Type: application/json' \
  --data-binary '{"role":"Creator","level":"L1","courseId":"demo"}' \
  "${CANDIDATE_BASE}/api/session/start" || true)"
SID="$(printf '%s' "$start" | (have jq && jq -r .sessionId) || echo "")"
MOVE="$(printf '%s' "$start" | (have jq && jq -r '.moves[0].id') || echo "")"
if [[ -n "$SID" && -n "$MOVE" && "$SID" != "null" && "$MOVE" != "null" ]]; then
  curl --max-time 10 -N -sS \
    -H 'Accept: text/event-stream' -H 'Content-Type: application/json' \
    -X POST --data-binary "{\"sessionId\":\"$SID\",\"moveId\":\"$MOVE\",\"messages\":[{\"role\":\"user\",\"content\":\"Kick off.\"}],\"maxTokens\":128}" \
    "${CANDIDATE_BASE}/api/tutor/stream" | sed -n '1,8p' || true
  ok "SSE responded"
else
  warn "Could not start a session; skipping SSE stream probe"
fi

# -------- 3) Vercel — recent prod deployments & (optionally) team/project IDs --------
if [[ -n "${VERCEL_TOKEN:-}" ]] && have jq; then
  hdr "Vercel — latest production deployments (READY first)"
  HDRS=(-H "Authorization: Bearer $VERCEL_TOKEN" -H "Content-Type: application/json")

  TEAM_ID="$(curl -fsSL "${HDRS[@]}" "https://api.vercel.com/v2/teams?slug=${TEAM_SLUG}" | jq -r '.id // empty')" || true
  PROJ_ID="$(curl -fsSL "${HDRS[@]}" "https://api.vercel.com/v9/projects/${PROJ}${TEAM_ID:+?teamId=${TEAM_ID}}"
            | jq -r '.id')" || true

  if [[ -n "${PROJ_ID:-}" ]]; then
    curl -fsSL "${HDRS[@]}" \
      "https://api.vercel.com/v13/deployments?projectId=${PROJ_ID}&target=production&limit=10${TEAM_ID:+&teamId=${TEAM_ID}}" \
      | jq -r '
          .deployments
          | sort_by(.created) | reverse
          | (["created","readyState","url"] | @tsv),
            ( .[] | [ (.created|tostring), (.readyState // .state), .url ] | @tsv )
        ' \
      | column -t
    ok "Listed recent prod deployments"
  else
    warn "Could not resolve projectId for ${PROJ}"
  fi
else
  hdr "Vercel — skipped"
  echo "Set VERCEL_TOKEN and install jq to show deployment list."
fi

hdr "Summary"
echo "Repo:           $REPO"
echo "Workflow match: '$WORKFLOW_FILTER'"
echo "Alias/Base:     $CANDIDATE_BASE"
echo "Team/Project:   ${TEAM_SLUG} / ${PROJ}"
echo "Done."
