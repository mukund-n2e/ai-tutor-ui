#!/usr/bin/env bash
set -euo pipefail
DIR="web/public/design/expected"
NEEDED=( landing onboarding-role onboarding-readiness quickwin-proposal session validator ship )
MISS=0
for k in "${NEEDED[@]}"; do
  for bp in desktop mobile; do
    f="$DIR/$k-$bp.png"
    if [ ! -f "$f" ]; then
      echo "Missing baseline: $f"
      MISS=1
    fi
  done
done
if [ "${STRICT_BASELINES:-1}" = "1" ] && [ $MISS -ne 0 ]; then
  echo "Strict baselines required; failing."
  exit 9
fi


