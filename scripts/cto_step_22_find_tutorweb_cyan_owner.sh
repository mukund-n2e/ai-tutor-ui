#!/usr/bin/env bash
set -euo pipefail

DOMAIN="tutorweb-cyan.vercel.app"
# The three teams you showed in CLI:
TEAMS=("ai-tutor-7f989507" "ai-tutor-17c6b7ef" "ai-tutor3")

found=""

for team in "${TEAMS[@]}"; do
  echo "Checking team: $team"

  # Check Custom Domains list
  if vercel domains ls --scope "$team" 2>/dev/null | awk '{print $1}' | grep -qx "$DOMAIN"; then
    echo "OWNER_SCOPE=$team OWNER_TYPE=domain"
    found="$team"
    break
  fi

  # Check Aliases list (older projects)
  if vercel alias ls --scope "$team" 2>/dev/null | awk '{print $1}' | grep -qx "$DOMAIN"; then
    echo "OWNER_SCOPE=$team OWNER_TYPE=alias"
    found="$team"
    break
  fi

  # If it's a system project domain, it matches a project name
  if vercel projects ls --scope "$team" 2>/dev/null | awk '{print $1}' | grep -qx "tutorweb-cyan"; then
    echo "OWNER_SCOPE=$team OWNER_TYPE=system PROJECT=tutorweb-cyan"
    found="$team"
    break
  fi
done

if [ -z "$found" ]; then
  echo "NOT_FOUND"
fi
