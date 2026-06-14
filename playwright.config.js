// playwright.config.js
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./test/integration",
  fullyParallel: false,
  workers: 1,
  reporter: "list",
  use: {
    // Set localhost as the base URL to eliminate CORS and file:// protocol restrictions
    baseURL: "http://localhost:8080",
    trace: "on-first-retry",
  },
  // Automatically spin up a static web server before starting the browser tests
  webServer: {
    command: "npx servor . --browse false --port 8080",
    url: "http://localhost:8080",
    reuseExistingServer: !process.env.CI,
    timeout: 10 * 1000,
  },
});
