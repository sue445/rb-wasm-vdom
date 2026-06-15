// playwright.config.js
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./test/integration",
  fullyParallel: false,
  workers: 1,
  reporter: "list",
  use: {
    baseURL: "http://localhost:8080",
    trace: "on-first-retry",
  },

  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        launchOptions: {
          headless: true, // Playwright itself is strictly headless
        },
      },
    },
  ],

  webServer: {
    command: "npx http-server . -p 8080 --silent",
    url: "http://localhost:8080",
    reuseExistingServer: !process.env.CI,
    timeout: 10 * 1000,
  },
});
