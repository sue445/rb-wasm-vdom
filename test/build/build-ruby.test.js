import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

const rootDir = process.cwd();
const outputFile = path.join(rootDir, 'dist', 'rb-wasm-vdom.rb');

const readBundledCode = () => {
  execFileSync('node', ['scripts/build-ruby.js'], {
    cwd: rootDir,
    stdio: 'pipe'
  });

  assert.equal(fs.existsSync(outputFile), true, `${outputFile} should exist`);

  return fs.readFileSync(outputFile, 'utf-8');
};

const countOccurrences = (text, pattern) => {
  return text.match(pattern)?.length ?? 0;
};

test('build-ruby.js generates dist/rb-wasm-vdom.rb', () => {
  readBundledCode();

  assert.equal(fs.existsSync(outputFile), true);
});

test('generated Ruby bundle keeps magic comments only at the beginning', () => {
  const bundledCode = readBundledCode();

  assert.equal(
    bundledCode.startsWith('# frozen_string_literal: true\n# rbs_inline: enabled\n\n'),
    true
  );

  assert.equal(
    countOccurrences(bundledCode, /^# frozen_string_literal: true$/gm),
    1
  );

  assert.equal(
    countOccurrences(bundledCode, /^# rbs_inline: enabled$/gm),
    1
  );
});

test('generated Ruby bundle contains expected rb-wasm-vdom definitions', () => {
  const bundledCode = readBundledCode();

  assert.match(bundledCode, /module RbWasmVdom/);
  assert.match(bundledCode, /class VNode/);
  assert.match(bundledCode, /class ReactiveState/);
  assert.match(bundledCode, /class TemplateParser/);
  assert.match(bundledCode, /module DomRenderer/);
  assert.match(bundledCode, /module Patcher/);
  assert.match(bundledCode, /class Interpolator/);
  assert.match(bundledCode, /class App/);
  assert.match(bundledCode, /def self\.create_app/);
});

test('generated Ruby bundle does not contain source-file require_relative lines', () => {
  const bundledCode = readBundledCode();

  assert.doesNotMatch(bundledCode, /^require_relative\b/m);
});
