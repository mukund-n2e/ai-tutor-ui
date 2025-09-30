import { test, expect } from '@playwright/test';

const base = process.env.E2E_BASE_URL || 'http://localhost:3000';

test.describe('Wall', () => {
  test('should load wall page', async ({ page }) => {
    await page.goto(`${base}/wall`);
    await expect(page).toHaveTitle(/AI Tutor/);
    await expect(page.getByRole('heading', { name: 'Pick a quick win' })).toBeVisible();
  });
});
