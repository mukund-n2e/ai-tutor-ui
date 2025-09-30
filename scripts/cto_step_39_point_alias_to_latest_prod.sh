#!/usr/bin/env bash
set -euo pipefail
TEAM="ai-tutor-7f989507"
PROJECT="ai-tutor-web"
ALIAS="tutorweb-cyan.vercel.app"

# Find the most recent READY Production deployment URL for the project
LATEST_URL="$(
  vercel ls "$PROJECT" --json --scope "$TEAM" 2>/dev/null \
  | node -e 'let d="";process.stdin.on("data",c=>d+=c);process.stdin.on("end",()=>{
      let j=JSON.parse(d); let arr=Array.isArray(j)?j:(j.deployments||[]);
      arr=arr.filter(x=> (x.target==="production"||x.environment==="production") && (!x.readyState || x.readyState==="READY"));
      arr.sort((a,b)=> (b.createdAt||b.created||0) - (a.createdAt||a.created||0));
      let u=arr[0]?.url||""; if(!u) process.exit(2);
      console.log(u.startsWith("https://")?u:`https://${u}`);
  });'
)"

vercel alias set "$LATEST_URL" "$ALIAS" --scope "$TEAM" >/dev/null
echo "alias-updated -> $LATEST_URL"
