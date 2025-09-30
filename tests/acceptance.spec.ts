import { test, expect } from '@playwright/test';

test.describe.configure({ retries: process.env.CI ? 1 : 0 });

const BASE = process.env.BASE_URL ?? 'https://tutorweb-cyan.vercel.app';

test.describe('PG-001 Landing', () => {
  test('copy, routing, and CTA presence', async ({ page }) => {
    await page.goto(BASE + '/');
    await expect(page.locator('main')).toBeVisible();
    // Tolerate either hero phrasing
    await expect(
      page.getByText(/(learn by doing|Learn and apply AI to your job)/i)
    ).toBeVisible();

    // Primary CTA present
    const primary = page.getByRole('link', { name: /Try the tutor|Start onboarding/i });
    await expect(primary).toBeVisible();

    // Secondary CTA present and robust to href
    const demoCta = page.locator('a[href^="/demo"], a[href^="/samples"]');
    await expect(demoCta).toBeVisible();
    await expect(demoCta).toBeEnabled();
    await expect.soft(demoCta).toHaveAccessibleName(/watch.*demo|samples/i);
  });

  test('responsive smoke (desktop + mobile)', async ({ page }) => {
    await page.setViewportSize({ width: 1440, height: 900 });
    await page.goto(BASE + '/');
    await expect(page.getByText(/(learn by doing|Learn and apply AI to your job)/i)).toBeVisible();

    await page.setViewportSize({ width: 390, height: 844 });
    await expect(page.getByText(/(learn by doing|Learn and apply AI to your job)/i)).toBeVisible();
  });
});

test.describe('PG-002 Role → PG-003 Readiness → PG-004 Proposal', () => {
  test('role persisted; scoring → L3', async ({ page }) => {
    await page.goto(BASE + '/onboarding/role');
    await expect(page.getByText('🎤 You can speak your choice')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Continue' })).toBeDisabled();

    await page.getByRole('button', { name: 'Creator' }).click();
    await expect(page.getByRole('button', { name: 'Continue' })).toBeEnabled();
    await page.getByRole('button', { name: 'Continue' }).click();

    // Readiness: set q1=Daily(4), q2=Confident(4), q3=Yes, regularly(4)
    await page.getByLabel('Used AI tools?').getByRole('radio', { name: 'Daily' }).check();
    await page.getByLabel('Comfort editing AI output?').getByRole('radio', { name: 'Confident' }).check();
    await page.getByLabel('Do you automate anything today?').getByRole('radio', { name: 'Yes, regularly' }).check();
    // q4 can be anything; should not affect score
    await page.getByLabel('Guidance style (not scored):').getByRole('radio', { name: 'Just the steps' }).check();

    await page.getByRole('button', { name: 'Continue' }).click();

    // Proposal shows personalization
    await expect(page.getByRole('heading', { name: 'Your Quick Win' })).toBeVisible();
    await expect(page.getByText(/Curated for Creator at Level L3/)).toBeVisible();
    // Preview shows 3 hero moves in some list-like container
    await expect(page.getByTestId('hero-move').first()).toBeVisible();
  });

  test('q4 does not change level (L1 path)', async ({ page }) => {
    await page.goto(BASE + '/onboarding/role');
    await page.getByRole('button', { name: 'Creator' }).click();
    await page.getByRole('button', { name: 'Continue' }).click();

    // q1=Never(0), q2=Not comfortable(0), q3=No(0)
    await page.getByLabel('Used AI tools?').getByRole('radio', { name: 'Never' }).check();
    await page.getByLabel('Comfort editing AI output?').getByRole('radio', { name: 'Not comfortable' }).check();
    await page.getByLabel('Do you automate anything today?').getByRole('radio', { name: 'No' }).check();
    // Flip q4 across options and confirm still L1
    for (const style of ['Hand-holding', 'Balanced', 'Just the steps']) {
      await page.getByLabel('Guidance style (not scored):').getByRole('radio', { name: style }).check();
      await page.getByRole('button', { name: 'Continue' }).click();
      await expect(page.getByText(/Level L1/)).toBeVisible();
      await page.goBack();
    }
  });
});

test.describe('PG-005 Session', () => {
  test('start session, see 3 moves, auto-scroll', async ({ page }) => {
    // Run through onboarding quickly (assumes prior tests didn’t persist)
    await page.goto(BASE + '/onboarding/role');
    await page.getByRole('button', { name: 'Creator' }).click();
    await page.getByRole('button', { name: 'Continue' }).click();
    await page.getByLabel('Used AI tools?').getByRole('radio', { name: 'Daily' }).check();
    await page.getByLabel('Comfort editing AI output?').getByRole('radio', { name: 'Confident' }).check();
    await page.getByLabel('Do you automate anything today?').getByRole('radio', { name: 'Yes, regularly' }).check();
    await page.getByRole('button', { name: 'Continue' }).click();

    await page.getByRole('button', { name: 'Start' }).click();
    await expect(page).toHaveURL(/\/session$/);

    // Move cards visible
    const cards = page.getByTestId('move-card');
    await expect(cards).toHaveCount(3);

    // Send a message and expect streaming to append chunks
    await page.getByPlaceholder(/Type/).fill('Kick off the first move.');
    await page.keyboard.press('Enter');
    await expect(page.getByTestId('chat-message').last()).toBeVisible();
    // Naive auto-scroll check: last message should be within viewport
    const last = page.getByTestId('chat-message').last();
    await expect(last).toBeInViewport();
  });

  test('after 3 moves → /validator', async ({ page }) => {
    // This assumes UI provides a clear way to mark a move done.
    await page.goto(BASE + '/session');
    for (let i = 0; i < 3; i++) {
      const btn = page.getByRole('button', { name: /Complete move|Next/i }).first();
      if (await btn.isVisible()) await btn.click();
    }
    await expect(page).toHaveURL(/\/validator$/);
  });
});

test.describe('PG-006 Validator → PG-007 Export', () => {
  test('pass state gates to export; filename format', async ({ page }) => {
    await page.goto(BASE + '/validator');
    // If canShip is already true, button should route to /export
    const ship = page.getByRole('button', { name: 'Ship Your Work' });
    if (await ship.isVisible()) {
      await ship.click();
      await expect(page).toHaveURL(/\/export$/);
    } else {
      // Otherwise go back and nudge to complete moves; soft assert
      test.skip(true, 'Validator not in pass state; run in staging with a passing artifact.');
    }

    // Export checks
    await expect(page.getByRole('heading', { name: 'Export Your Work' })).toBeVisible();

    // Copy to clipboard
    const copy = page.getByRole('button', { name: /Copy|Copy to clipboard/i });
    if (await copy.isVisible()) {
      await copy.click();
      const clip = await page.evaluate(() => navigator.clipboard.readText());
      expect(clip.length).toBeGreaterThan(10);
    }

    // Download (listen for download event)
    const [download] = await Promise.all([
      page.waitForEvent('download'),
      page.getByRole('button', { name: /Download|Save/i }).click()
    ]);
    const fname = download.suggestedFilename();
    expect(fname).toMatch(/.+_.+_\d{4}-\d{2}-\d{2}\.md$/);
  });
});
