import { readFileSync } from 'node:fs';
import { defineConfig } from 'vite';

const stripRubyBundlerOnlyLines = (code) => {
  return code
    .replace(/^\s*#\s*frozen_string_literal:\s*true\s*$/gm, '')
    .replace(/^\s*#\s*rbs_inline:\s*enabled\s*$/gm, '')
    .replace(/^\s*require_relative\s+["'][^"']+["']\s*$/gm, '')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
};

const rubyRawPlugin = () => {
  return {
    name: 'ruby-raw',
    enforce: 'pre',
    load(id) {
      const [filePath, query] = id.split('?');

      if (!filePath.endsWith('.rb') || query !== 'raw') {
        return null;
      }

      const code = stripRubyBundlerOnlyLines(readFileSync(filePath, 'utf-8'));

      return {
        code: `export default ${JSON.stringify(code)};`,
        map: null
      };
    }
  };
};

export default defineConfig({
  plugins: [
    rubyRawPlugin()
  ],
  build: {
    // Configure Vite to build as a library instead of a web app
    lib: {
      // Specify the entry point of the library
      entry: 'src/index.js',
      // Global variable name for the IIFE build (used in <script> tags)
      name: 'RbWasmVdom',
      // Output file naming pattern
      fileName: (format) => `rb-wasm-vdom.${format}.js`,
      // Output formats: ES Module (for npm) and IIFE (for CDN)
      formats: ['es', 'iife']
    },
    // Specify the output directory
    outDir: 'dist',
    // Clean the output directory before each build
    emptyOutDir: false
  }
});
