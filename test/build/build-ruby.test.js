import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

const rootDir = process.cwd();
const outputFile = path.join(rootDir, 'dist', 'rb-wasm-vdom.rb');
const sourceDir = path.join(rootDir, 'src', 'rb_wasm_vdom');

const magicCommentLines = [
  '# frozen_string_literal: true',
  '# rbs_inline: enabled'
];

const escapeRegExp = (text) => {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
};

const stripMagicComments = (code) => {
  let strippedCode = code;

  for (const line of magicCommentLines) {
    strippedCode = strippedCode.replace(new RegExp(`^${escapeRegExp(line)}\\r?\\n?`, 'gm'), '');
  }

  return strippedCode.trimStart();
};

const sourceFiles = () => {
  return fs.readdirSync(sourceDir)
    .filter(file => file.endsWith('.rb'))
    .sort()
    .map(file => path.join(sourceDir, file));
};

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

  for (const file of sourceFiles()) {
    const sourceCode = stripMagicComments(fs.readFileSync(file, 'utf-8'));

    assert.match(
      bundledCode,
      new RegExp(escapeRegExp(sourceCode)),
      `${path.relative(rootDir, file)} should be included in generated Ruby bundle`
    );
  }

  assert.match(bundledCode, /module RbWasmVdom/);
  assert.match(bundledCode, /def self\.create_app/);
});

test('generated Ruby bundle does not contain source-file require_relative lines', () => {
  const bundledCode = readBundledCode();

  assert.doesNotMatch(bundledCode, /^require_relative\b/m);
});
