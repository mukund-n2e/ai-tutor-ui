import { test, expect } from '@playwright/test';

const base = process.env.E2E_BASE_URL || 'http://localhost:3000';

test.describe('Outline', () => {
  test('should load pricing page', async ({ page }) => {
    await page.goto(`${base}/pricing`);
    await expect(page).toHaveTitle(/AI Tutor/);
    await expect(page.getByRole('heading', { name: 'Pick your level' })).toBeVisible();
  });
});
