import { defineConfig } from 'vite';

export default defineConfig({
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
