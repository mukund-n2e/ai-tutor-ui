import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    include: ['tests/**/*.test.ts'],
    environment: 'node',
    globals: true,
    watch: false,
    coverage: { provider: 'v8', reporter: ['text','lcov'] }
  }
});
