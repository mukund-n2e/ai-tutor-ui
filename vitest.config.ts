import { defineConfig } from 'vitest/config';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export default defineConfig({
  test: {
    include: ['tests/**/*.test.ts'],
    environment: 'node',
    globals: true,
    watch: false,
    coverage: { provider: 'v8', reporter: ['text','lcov'] }
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src')
    }
  }
});
