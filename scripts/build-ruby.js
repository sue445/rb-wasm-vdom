import fs from 'fs';
import path from 'path';

// Get the project root directory when executed via npm run
const rootDir = process.cwd();

const magicCommentLines = [
  '# frozen_string_literal: true',
  '# rbs_inline: enabled'
];

const magicCommentBlock = `${magicCommentLines.join('\n')}\n\n`;

const stripMagicComments = code => {
  let strippedCode = code;

  for (const line of magicCommentLines) {
    strippedCode = strippedCode.replace(new RegExp(`^${line.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\r?\\n?`, 'gm'), '');
  }

  return strippedCode.trimStart();
};

// Specify the files to bundle in dependency order
const files = [
  'src/rb_wasm_vdom/vnode.rb',
  'src/rb_wasm_vdom/reactive_state.rb',
  'src/rb_wasm_vdom/template_parser.rb',
  'src/rb_wasm_vdom/dom_renderer.rb',
  'src/rb_wasm_vdom/patcher.rb',
  'src/rb_wasm_vdom/interpolator.rb',
  'src/rb_wasm_vdom/conditional_renderer.rb',
  'src/rb_wasm_vdom/directive_renderer.rb',
  'src/rb_wasm_vdom/app.rb',
  'src/rb_wasm_vdom.rb'
];

// Output directory and file name (resolved as absolute paths)
const outputDir = path.join(rootDir, 'dist');
const outputFile = path.join(outputDir, 'rb-wasm-vdom.rb');

// Create the dist directory if it does not exist
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir);
}

// Read files and concatenate them with double line breaks
const bundledCode = magicCommentBlock + files.map(file => {
  const filePath = path.join(rootDir, file);
  return stripMagicComments(fs.readFileSync(filePath, 'utf-8'));
}).join('\n\n');

// Write the bundled code to the output file
fs.writeFileSync(outputFile, bundledCode);

console.log(`✅ Ruby bundle generated at ${outputFile}`);
