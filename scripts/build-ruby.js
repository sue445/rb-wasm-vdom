// scripts/build-ruby.js
import fs from 'fs';
import path from 'path';

// Get the project root directory when executed via npm run
const rootDir = process.cwd();

// Specify the files to bundle in dependency order
const files = [
  'src/rb_wasm_vdom/vnode.rb',
  'src/rb_wasm_vdom/reactive_state.rb',
  'src/rb_wasm_vdom/template_parser.rb',
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
const bundledCode = files.map(file => {
  const filePath = path.join(rootDir, file);
  return fs.readFileSync(filePath, 'utf-8');
}).join('\n\n');

// Write the bundled code to the output file
fs.writeFileSync(outputFile, bundledCode);

console.log(`✅ Ruby bundle generated at ${outputFile}`);
