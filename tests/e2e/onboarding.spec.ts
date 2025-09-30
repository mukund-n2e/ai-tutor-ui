import { test, expect } from '@playwright/test';

const base = process.env.E2E_BASE_URL || 'http://localhost:3000';

test.describe('Onboarding', () => {
  test('should load onboarding page', async ({ page }) => {
    await page.goto(`${base}/onboarding`);
    await expect(page).toHaveTitle(/AI Tutor/);
    await expect(page.getByRole('heading', { name: 'Start a session' })).toBeVisible();
  });
});
