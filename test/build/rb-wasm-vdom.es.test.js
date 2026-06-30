import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const rootDir = process.cwd();
const outputFile = path.join(rootDir, "dist", "rb-wasm-vdom.es.js");
const sourceDir = path.join(rootDir, "src", "rb_wasm_vdom");
const mainSourceFile = path.join(rootDir, "src", "rb_wasm_vdom.rb");

const sourceFiles = () => {
  const files = fs.readdirSync(sourceDir)
    .filter(file => file.endsWith(".rb"))
    .sort()
    .map(file => path.join(sourceDir, file));

  return [
    ...files,
    mainSourceFile
  ];
};

const buildViteBundle = () => {
  execFileSync("npx", ["vite", "build"], {
    cwd: rootDir,
    stdio: "pipe"
  });

  assert.equal(fs.existsSync(outputFile), true, `${outputFile} should exist`);
};

const importBuiltBundle = async () => {
  const moduleUrl = `${path.toNamespacedPath(outputFile)}?cacheBust=${Date.now()}`;
  return import(moduleUrl);
};

const captureEvaluatedCode = async () => {
  buildViteBundle();

  global.window = {};

  const evaluatedCode = [];
  const vm = {
    eval(code) {
      evaluatedCode.push(code);
    }
  };

  const { createApp } = await importBuiltBundle();

  createApp(vm, {
    el: "#app",
    template: "<div>{{ message }}</div>",
    state: {
      message: "Hello"
    },
    methods: {}
  });

  return evaluatedCode;
};

test("index.js can be imported and createApp can be used from the built bundle", async () => {
  const evaluatedCode = await captureEvaluatedCode();

  assert.equal(evaluatedCode.length, 2);
  assert.match(evaluatedCode[0], /module RbWasmVdom/);
  assert.match(evaluatedCode[1], /RbWasmVdom\.create_app\("#app"/);

  assert.deepEqual(window.__rb_vdom_state, {
    message: "Hello"
  });
  assert.deepEqual(window.__rb_vdom_methods, {});
});

test("rb-wasm-vdom.es.js includes all src/rb_wasm_vdom/*.rb files", async () => {
  const evaluatedCode = await captureEvaluatedCode();
  const frameworkRubyCode = evaluatedCode[0];

  for (const file of sourceFiles()) {
    const sourceCode = fs.readFileSync(file, "utf-8");

    assert.match(
      frameworkRubyCode,
      new RegExp(sourceCode.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")),
      `${path.relative(rootDir, file)} should be included in rb-wasm-vdom.es.js`
    );
  }
});
