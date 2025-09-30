#!/usr/bin/env bash
set -euo pipefail

# -------- Config (env overrides allowed) ----------
BASE="${BASE:-https://tutorweb-cyan.vercel.app}"

# Copy matching:
RELAXED_COPY="${RELAXED_COPY:-0}"  # 1 => don't enforce exact landing copy text

# CTA text labels (adjust if copy intentionally changed):
PRIMARY_CTA_TEXT="${PRIMARY_CTA_TEXT:-Start from your work}"
SECONDARY_CTA_TEXT="${SECONDARY_CTA_TEXT:-Try a sample}"

# Allowed hrefs (regex). Default = strict spec; widen to allow '/app' etc.
PRIMARY_CTA_ALLOWED="${PRIMARY_CTA_ALLOWED:-^/onboarding(/role)?([/?#]|$)}"
SECONDARY_CTA_ALLOWED="${SECONDARY_CTA_ALLOWED:-^/samples([/?#]|$)}"

# Other checks:
ALLOW_SCREENS_REDIRECT="${ALLOW_SCREENS_REDIRECT:-0}"  # 1 => accept 30x on /screens
VERBOSE="${VERBOSE:-1}"

die(){ echo "❌ $*" >&2; exit 1; }
ok(){ echo "✅ $*"; }
info(){ [[ "${VERBOSE}" = "1" ]] && echo "ℹ️  $*"; }

# -------- Fetch landing ----------
landing="$(curl -fsSL --compressed -L "$BASE/" || die "GET $BASE/ failed")"
landing_oneline="$(printf '%s' "$landing" | tr '\n' ' ')"

# -------- Landing copy (spec exact unless relaxed) ----------
if [[ "$RELAXED_COPY" != "1" ]]; then
  grep -Fq "Learn and apply AI to your job. No fluff." <<<"$landing" \
    || die "Landing H1 mismatch"
  grep -Fq "Pick a job task. We'll guide three decisive moves, validate, and you're done." <<<"$landing" \
    || die "Landing subtitle mismatch"
  grep -Fq "Incognito by default. Nothing saved unless you say so." <<<"$landing" \
    || die "Footer copy mismatch"
  ok "Landing copy matches spec"
else
  info "RELAXED_COPY=1 → skipping exact landing copy match"
fi

# -------- Utilities ----------
extract_href_by_text() {
  # Robust anchor finder: matches <a ... href="...">...Start from your work...</a> across lines.
  local html="$1" text="$2"
  TEXT="$text" perl -0777 -ne '
    my $t=$ENV{"TEXT"};
    while (/<a[^>]*href="([^"]+)"[^>]*>.*?\Q$t\E.*?<\/a>/sig) { print "$1\n"; }
  ' <<<"$html" | head -n1
}

# -------- CTA checks ----------
primary_href="$(extract_href_by_text "$landing_oneline" "$PRIMARY_CTA_TEXT" || true)"
secondary_href="$(extract_href_by_text "$landing_oneline" "$SECONDARY_CTA_TEXT" || true)"

# If label changed but RELAXED_COPY=1, allow a best-effort match by URL pattern:
if [[ -z "${primary_href:-}" && "$RELAXED_COPY" == "1" ]]; then
  primary_href="$(
    perl -0777 -ne 'print "$1\n" while /<a[^>]*href="([^"]+)"/sig' <<<"$landing_oneline" \
      | grep -E "$PRIMARY_CTA_ALLOWED" | head -n1 || true
  )"
  [[ -n "${primary_href:-}" ]] && info "Primary CTA text not found; matched by URL pattern (RELAXED_COPY=1)"
fi

[[ -n "${primary_href:-}" ]] || die "Primary CTA ('$PRIMARY_CTA_TEXT') anchor not found"
[[ "$primary_href" =~ $PRIMARY_CTA_ALLOWED ]] \
  || die "Primary CTA href '$primary_href' did not match allowed pattern: $PRIMARY_CTA_ALLOWED"
ok "Primary CTA → $primary_href (allowed)"

if [[ -n "${secondary_href:-}" ]]; then
  [[ "$secondary_href" =~ $SECONDARY_CTA_ALLOWED ]] \
    || die "Secondary CTA href '$secondary_href' did not match allowed pattern: $SECONDARY_CTA_ALLOWED"
  ok "Secondary CTA → $secondary_href (allowed)"
else
  info "Secondary CTA ('$SECONDARY_CTA_TEXT') not found; skipping"
fi

# -------- /screens check (200 or allowed redirect) ----------
screens_code="$(curl -s -o /dev/null -w "%{http_code}" -L "$BASE/screens")"
if [[ "$screens_code" == "200" ]]; then
  ok "/screens → 200"
elif [[ "$ALLOW_SCREENS_REDIRECT" == "1" && "$screens_code" =~ ^30[1278]$ ]]; then
  ok "/screens → $screens_code (allowed by ALLOW_SCREENS_REDIRECT=1)"
else
  die "/screens → $screens_code"
fi

# -------- flags.json sanity ----------
flags_headers="$(curl -sSI "$BASE/flags.json")"
echo "$flags_headers" | grep -iq 'content-type: *application/json' \
  || die "flags.json content-type not JSON"
flags="$(curl -fsS --compressed "$BASE/flags.json")"
echo "$flags" | jq -e . >/dev/null || die "flags.json is not valid JSON"
echo "$flags" | jq -e '.beta == true' >/dev/null || info "flags.beta != true (non-blocking)"
ok "flags.json valid"

# -------- Session SSR marker (non-blocking if you prefer) ----------
sess="$(curl -fsSL --compressed "$BASE/session" || true)"
if grep -Fq 'data-ssr-moves="' <<<"$sess"; then
  ok "Session SSR marker present"
else
  info "SSR marker not found (non-blocking)"
fi

echo "== DONE =="
