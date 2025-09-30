import type { NextConfig } from "next";

const csp = [
  "default-src 'self'",
  "base-uri 'self'",
  "img-src 'self' data:",
  "style-src 'self' 'unsafe-inline'",
  "script-src 'self' 'unsafe-inline'",
  "connect-src 'self' https://*.amazonaws.com https://*.openai.com https://*.posthog.com wss://*.amazonaws.com",
  "frame-ancestors 'none'",
].join('; ');

const securityHeaders: { key: string; value: string }[] = [
  { key: 'Content-Security-Policy', value: csp },
  { key: 'Strict-Transport-Security', value: 'max-age=15552000; includeSubDomains' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
];

const streamHeaders: { key: string; value: string }[] = [
  { key: 'Cache-Control', value: 'no-cache, no-transform' },
  { key: 'Content-Type', value: 'text/event-stream' },
  { key: 'Connection', value: 'keep-alive' },
];

const nextConfig: NextConfig = {
  async headers() {
    return [
      { source: '/(.*)', headers: securityHeaders },
      { source: '/api/tutor/stream', headers: streamHeaders },
    ];
  },
};

export default nextConfig;
