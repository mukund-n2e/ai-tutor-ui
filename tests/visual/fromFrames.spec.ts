import { test, expect } from '@playwright/test';
import fs from 'fs';
import path from 'path';

const BASE = process.env.BASE_URL ?? 'https://tutorweb-cyan.vercel.app';
const framesPath = path.resolve('web/design/frames.json');
const frames = fs.existsSync(framesPath)
  ? JSON.parse(fs.readFileSync(framesPath, 'utf-8'))
  : { frames: {} };
const expectedDir = path.resolve('web/public/design/expected');

const routeFor = (key: string) => {
  switch (key) {
    case 'landing': return '/';
    case 'role': return '/onboarding/role';
    case 'readiness': return '/onboarding/readiness';
    case 'proposal': return '/onboarding/proposal';
    case 'session': return '/session';
    case 'validator': return '/validator';
    case 'export': return '/export';
    default: return null;
  }
};

const bps = [
  { name: 'desktop', width: 1440, height: 900, threshold: 0.015 },
  { name: 'mobile',  width:  390, height: 844, threshold: 0.020 },
];

test.describe('Visuals match baselines', () => {
  for (const [key] of Object.entries<any>(frames.frames)) {
    const route = routeFor(key);
    if (!route) continue;
    for (const bp of bps) {
      const baseline = path.join(expectedDir, `${key}-${bp.name}.png`);
      test(`${route} @${bp.name}`, async ({ page }) => {
        if (!fs.existsSync(baseline)) test.skip(true, `No baseline: ${baseline}`);
        await page.setViewportSize({ width: bp.width, height: bp.height });
        await page.goto(`${BASE}${route}`, { waitUntil: 'networkidle' });
        await page.evaluate(() => (document as any).fonts?.ready);
        const shot = await page.screenshot({ fullPage: true });
        expect(shot).toMatchSnapshot(`${key}-${bp.name}.png`, {
          threshold: bp.threshold,
          maxDiffPixelRatio: bp.threshold,
        });
      });
    }
  }
});


