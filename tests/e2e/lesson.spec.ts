import { test, expect } from '@playwright/test';

const base = process.env.E2E_BASE_URL || 'http://localhost:3000';

test.describe('Lesson', () => {
  test('should load lesson outline page', async ({ page }) => {
    await page.goto(`${base}/lesson/L1-05/outline`);
    await expect(page).toHaveTitle(/AI Tutor/);
    await expect(page.getByRole('heading', { name: /outline/i })).toBeVisible();
  });
});
