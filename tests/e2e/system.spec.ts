import { test, expect } from '@playwright/test';

const base = process.env.E2E_BASE_URL || 'http://localhost:3000';

test.describe('System routes', () => {
  test('checkout success', async ({ page }) => {
    await page.goto(`${base}/checkout/success?level=L2`);
    await expect(page.getByRole('heading', { name: 'Payment confirmed' })).toBeVisible();
  });

  test('checkout error', async ({ page }) => {
    await page.goto(`${base}/checkout/error`);
    await expect(page.getByRole('heading', { name: "Payment didn't go through" })).toBeVisible();
  });

  test('account sign in (stub)', async ({ page }) => {
    await page.goto(`${base}/account`);
    await expect(page.getByRole('heading', { name: 'Sign in' })).toBeVisible();
  });

  test('legal pages', async ({ page }) => {
    await page.goto(`${base}/legal/privacy`);
    await expect(page.getByRole('heading', { name: 'Privacy Policy' })).toBeVisible();
    await page.goto(`${base}/legal/terms`);
    await expect(page.getByRole('heading', { name: 'Terms of Use' })).toBeVisible();
  });
});
