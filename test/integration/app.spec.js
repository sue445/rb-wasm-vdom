import { test, expect } from "@playwright/test";
import fs from "fs/promises";
import path from "path";

const integration_test_files = [
  "picoruby-wasm-wasi-latest.html",
  "ruby-head-wasm-wasi.html"
];

async function assertBrowserTestResults(page) {
  // Assert the test result container updated by Ruby
  const testResultsEl = page.locator("#test-results");
  await expect(testResultsEl).toHaveAttribute("data-status", /success|failure/, { timeout: 15000 });
  await expect(testResultsEl).not.toHaveText("", { timeout: 15000 });

  const status = await testResultsEl.getAttribute("data-status");
  const rawResults = await testResultsEl.textContent();
  const results = JSON.parse(rawResults);

  console.log(`📊 Browser Test Summary: Passed: ${results.passed}, Errors: ${results.failed.length}`);

  if (status === "failure") {
    console.error("❌ Integration Test Failures:\n", results.failed.join("\n"));
  }

  expect(status).toBe("success");
}

for (const integration_test_file of integration_test_files) {
  test(`Ruby WASM VDOM Browser Integration Test with ${integration_test_file}`, async ({ page }) => {
    // Forward browser logs to console
    page.on("console", msg => console.log(`[Browser Console] ${msg.type()}: ${msg.text()}`));
    page.on("pageerror", err => console.error(`[Browser Error] ${err.message}`));

    // Open the clean HTML page via local dev server
    await page.goto(`/test/integration/fixture/${integration_test_file}`);

    await assertBrowserTestResults(page);
  });
}
