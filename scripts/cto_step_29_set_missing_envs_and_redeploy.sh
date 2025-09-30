#!/usr/bin/env bash
set -euo pipefail

TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
BASE_URL="https://tutorweb-cyan.vercel.app"
WS_URL="wss://tutorweb-cyan.vercel.app"

# Generate a stable encryption key if you don't already have one
if command -v openssl >/dev/null 2>&1; then
  NEXTEK="$(openssl rand -hex 32)"
else
  NEXTEK="$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | xxd -p -c 64)"
fi

TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
cat > "$TMP" <<ENV
CHARS_PER_TOKEN=4
NEXT_PUBLIC_BASE_URL=$BASE_URL
NEXT_PUBLIC_SHOW_SCREENS=true
NEXT_PUBLIC_SITE_URL=$BASE_URL
NEXT_PUBLIC_TUTOR_TRANSPORT=sse
NEXT_PUBLIC_WS_URL=$WS_URL
RL_MAX_REQUESTS=8
RL_WINDOW_SECONDS=60
SESSION_TOKEN_CAP=12000
ENV
echo "NEXT_SERVER_ACTIONS_ENCRYPTION_KEY=$NEXTEK" >> "$TMP"

vercel link --project "$PROJECT" --yes --scope "$TEAM" >/dev/null

while IFS='=' read -r KEY VAL; do
  [ -n "$KEY" ] || continue
  yes | vercel env rm "$KEY" production --scope "$TEAM" >/dev/null 2>&1 || true
  printf "%s" "$VAL" | vercel env add "$KEY" production --scope "$TEAM" >/dev/null
  echo "set $KEY"
done < "$TMP"

vercel redeploy "$BASE_URL" --scope "$TEAM" >/dev/null
echo "envs-updated"
