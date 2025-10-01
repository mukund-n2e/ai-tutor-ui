import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: 'tests/screens',
  timeout: 60000,
  reporter: [['list'], ['html', { outputFolder: 'playwright-report', open: 'never' }]],
  expect: { toHaveScreenshot: { maxDiffPixels: 0, animations: 'disabled', caret: 'hide' } },
  use: { deviceScaleFactor: 1, ignoreHTTPSErrors: true, trace: 'off' }
});