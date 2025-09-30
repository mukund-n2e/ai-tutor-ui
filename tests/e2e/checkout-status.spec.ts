import { test, expect } from '@playwright/test';

test.describe('Checkout status pages', () => {
  test('success page renders without session_id', async ({ page }) => {
    await page.goto('/checkout/success');
    await expect(page.getByTestId('co-success-title')).toBeVisible();
    await expect(page.getByRole('link', { name: /Start Level|Browse courses/i })).toBeVisible();
  });

  test('error page renders', async ({ page }) => {
    await page.goto('/checkout/error');
    await expect(page.getByTestId('co-error-title')).toBeVisible();
    await expect(page.getByTestId('co-error-retry')).toBeVisible();
  });
});

