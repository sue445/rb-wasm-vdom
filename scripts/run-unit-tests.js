// scripts/run-unit-tests.js
import fs from "fs/promises";
import { WASI } from "wasi";

async function main() {
  // Get the VM type from command line arguments (default to "ruby-wasm-head")
  const vmType = process.argv[2] || "ruby-wasm-head";

  let jsPkgName;
  let wasmPath;

  // Configure package names and paths based on the requested VM
  switch (vmType) {
    case "picoruby":
      jsPkgName = "picoruby-wasm";
      wasmPath = "node_modules/picoruby-wasm/dist/picoruby.wasm";
      break;
    case "ruby-wasm-head":
    default:
      jsPkgName = "@ruby/wasm-wasi";
      wasmPath = "node_modules/@ruby/head-wasm-wasi/dist/ruby.wasm";
      break;
  }

  console.log(`🚀 Running tests with VM: ${vmType}`);

  // Dynamically import the wrapper module and extract RubyVM
  const jsModule = await import(jsPkgName);
  const RubyVM = jsModule.RubyVM || jsModule.default?.RubyVM;

  if (typeof RubyVM !== "function") {
    throw new Error(`RubyVM class is not found in the exports of '${jsPkgName}'.`);
  }

  // Read the WASM binary from the local node_modules
  const wasmBuffer = await fs.readFile(wasmPath);
  const module = await WebAssembly.compile(wasmBuffer);

  // Set up WASI with minimal directory mapping to allow local file access
  const wasi = new WASI({
    version: "preview1",
    env: process.env,
    args: [],
    preopens: {
      ".": "."
    }
  });

  // Initialize RubyVM and its imports
  const vm = new RubyVM();
  const imports = {
    wasi_snapshot_preview1: wasi.wasiImport,
  };
  vm.addToImports(imports);

  // Instantiate the WebAssembly module and wire it up
  const instance = await WebAssembly.instantiate(module, imports);
  await vm.setInstance(instance);

  // Initialize WASI and Ruby VM in the correct order
  wasi.initialize(instance);
  vm.initialize();

  // Execute the custom test runner script
  vm.eval(`
    require "./test/unit/run.rb"
  `);
}

main().catch(err => {
  console.error(`❌ Test failed: ${err.message}`);
  process.exit(1);
});
