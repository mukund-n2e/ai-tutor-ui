import { test, expect } from '@playwright/test';

const base = process.env.E2E_BASE_URL || 'http://localhost:3000';

test.describe('Checkout', () => {
  test('should load checkout success page', async ({ page }) => {
    await page.goto(`${base}/checkout/success`);
    await expect(page).toHaveTitle(/AI Tutor/);
    await expect(page.getByRole('heading', { name: 'Payment confirmed' })).toBeVisible();
  });

  test('should load checkout error page', async ({ page }) => {
    await page.goto(`${base}/checkout/error`);
    await expect(page).toHaveTitle(/AI Tutor/);
    await expect(page.getByRole('heading', { name: /didn.*go through/i })).toBeVisible();
  });
});
