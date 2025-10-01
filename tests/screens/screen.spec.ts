import { test, expect } from '@playwright/test';
import fs from 'fs';
const manifest = JSON.parse(fs.readFileSync('screens.manifest.json','utf-8'));
for (const scr of manifest.screens) {
  for (const [vpName, size] of Object.entries(manifest.viewports)) {
    test(`${scr.key} @${vpName}`, async ({ page }) => {
      await page.setViewportSize(size as any);
      const url = manifest.baseUrl + scr.path;
      await page.goto(url, { waitUntil: 'domcontentloaded' });
      await page.waitForTimeout(250);
      await expect(page).toHaveScreenshot(`${scr.key}--${vpName}.png`, { fullPage: true });
    });
  }
}
