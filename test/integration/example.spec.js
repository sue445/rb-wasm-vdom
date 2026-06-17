import { test, expect } from "@playwright/test";

const example_files = [
  "example1-picoruby-wasm.html",
  "example1-ruby-wasm.html"
];

for (const example_file of example_files) {
  test(`/examples/${example_file} does not output browser console errors`, async ({ page }) => {
    const errors = [];

    page.on("console", msg => {
      console.log(`[Browser Console] ${msg.type()}: ${msg.text()}`);

      if (msg.type() === "error") {
        errors.push(`[console.error] ${msg.text()}`);
      }
    });

    page.on("pageerror", err => {
      errors.push(`[pageerror] ${err.message}`);
    });

    await page.goto(`/examples/${example_file}`);

    await expect(page.locator("#app .app-container")).toBeVisible({ timeout: 15000 });
    await expect(page.locator("#app")).toContainText("Ruby Reactivity App");

    expect(errors).toEqual([]);
  });
}
