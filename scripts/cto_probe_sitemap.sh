#!/usr/bin/env bash
set -euo pipefail
URL="${PROD_URL:-https://tutorweb-cyan.vercel.app}"
echo "Probing ${URL}/sitemap.xml …"
XML="$(curl -fsSL "$URL/sitemap.xml?nocache=$(date +%s)")"
check(){ echo "$XML" | grep -Eiq "<loc>.*$1/?</loc>" && echo "  $1 -> OK" || echo "  $1 -> MISSING"; }
check "/"
check "/courses"
check "/tutor"
check "/courses/getting-started"
