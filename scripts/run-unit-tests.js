import fs from "fs/promises";
import path from "path";
import { WASI } from "wasi";

async function main() {
  // Get the VM type from command line arguments (default to "ruby-wasm-head")
  const vmType = process.argv[2] || "ruby-wasm-head";

  console.log(`🚀 Running tests with VM: ${vmType}`);

  switch (vmType) {
    case "picoruby-wasm-wasi-latest":
      await runWithPicoRuby();
      break;
    case "ruby-wasm-head":
    default:
      await runWithRubyWasmHead();
      break;
  }
}

async function runWithRubyWasmHead() {
  const jsPkgName = "@ruby/wasm-wasi";
  const wasmPath = "node_modules/@ruby/head-wasm-wasi/dist/ruby.wasm";

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

async function runWithPicoRuby() {
  const { default: createModule } = await import("@picoruby/wasm-wasi/picoruby.js");
  const wasmBinary = await fs.readFile("node_modules/@picoruby/wasm-wasi/dist/picoruby.wasm");

  let testResult = null;

  const Module = await createModule({
    wasmBinary,
    noInitialRun: true,
    print: (text) => {
      console.log(text);

      const match = text.match(/^__RB_WASM_VDOM_UNIT_TEST_RESULT__:(\d+):(\d+)$/);
      if (match) {
        testResult = {
          passed: Number(match[1]),
          failed: Number(match[2])
        };
      }
    },
    printErr: (text) => {
      console.error(text);
    }
  });

  Module.ccall("picorb_init", "number", [], []);

  const libraryCode = await readRubyLibraryForPicoRuby();
  const testRunnerCode = await readRubyFileForPicoRuby("test/unit/run.rb");
  const [testFrameworkCode, testExecutionCode] = splitRubyTestRunner(testRunnerCode);
  const helperFiles = await listRubyFiles("test/unit/helper");
  const testFiles = await listRubyTestFiles("test/unit");
  const helperCodes = await Promise.all(
    helperFiles.map(file => readRubyFileForPicoRuby(file))
  );
  const testCodes = await Promise.all(
    testFiles.map(file => readRubyFileForPicoRuby(file))
  );

  const runnerCode = [
    "PICORUBY_CONCATENATED_TEST = true",
    'puts "PicoRuby runner started"',
    libraryCode,
    testFrameworkCode,
    ...helperCodes,
    ...testCodes,
    testExecutionCode
  ].join("\n\n");

  console.log("PicoRuby helper files:");
  for (const file of helperFiles) {
    console.log(`  /${file}`);
  }

  console.log("PicoRuby test files:");
  for (const file of testFiles) {
    console.log(`  /${file}`);
  }

  const taskResult = Module.ccall(
    "picorb_create_task",
    "number",
    ["string"],
    [runnerCode]
  );

  if (taskResult !== 0) {
    throw new Error(`picorb_create_task failed: ${taskResult}`);
  }

  const result = await runPicoRubyUntilResult(Module, () => testResult);

  if (result.failed > 0) {
    throw new Error(`PicoRuby unit tests failed: ${result.failed} failed.`);
  }
}

async function readRubyLibraryForPicoRuby() {
  const libraryFiles = [
    "src/rb_wasm_vdom/vnode.rb",
    "src/rb_wasm_vdom/reactive_state.rb",
    "src/rb_wasm_vdom/interpolator.rb",
    "src/rb_wasm_vdom/template_parser.rb",
    "src/rb_wasm_vdom/dom_renderer.rb",
    "src/rb_wasm_vdom/patcher.rb",
    "src/rb_wasm_vdom/each_renderer.rb",
    "src/rb_wasm_vdom/app.rb",
    "src/rb_wasm_vdom.rb"
  ];

  const codes = await Promise.all(
    libraryFiles.map(file => readRubyFileForPicoRuby(file))
  );

  return codes.join("\n\n");
}

function splitRubyTestRunner(code) {
  const marker = "# Test runner execution logic";
  const markerIndex = code.indexOf(marker);

  if (markerIndex === -1) {
    throw new Error(`Could not find '${marker}' in test/unit/run.rb`);
  }

  const frameworkCode = code.slice(0, markerIndex);
  const executionCode = code.slice(markerIndex);

  return [frameworkCode, executionCode];
}

async function readRubyFileForPicoRuby(filePath) {
  const content = await fs.readFile(filePath, "utf-8");

  return content
    .split("\n")
    .filter(line => !line.trimStart().startsWith("require_relative "))
    .join("\n");
}

async function listRubyTestFiles(directory) {
  const entries = await fs.readdir(directory, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const filePath = path.join(directory, entry.name);

    if (entry.isDirectory()) {
      files.push(...await listRubyTestFiles(filePath));
      continue;
    }

    if (entry.isFile() && filePath.endsWith("_test.rb")) {
      files.push(filePath);
    }
  }

  return files.sort();
}

async function listRubyFiles(directory) {
  const entries = await fs.readdir(directory, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const filePath = path.join(directory, entry.name);

    if (entry.isDirectory()) {
      files.push(...await listRubyFiles(filePath));
      continue;
    }

    if (entry.isFile() && filePath.endsWith(".rb")) {
      files.push(filePath);
    }
  }

  return files.sort();
}

async function mountRubyFiles(Module, directory) {
  const entries = await fs.readdir(directory, { withFileTypes: true });

  createDirectory(Module, `/${directory}`);

  for (const entry of entries) {
    const filePath = path.join(directory, entry.name);

    if (entry.isDirectory()) {
      await mountRubyFiles(Module, filePath);
      continue;
    }

    if (!entry.isFile() || !filePath.endsWith(".rb")) {
      continue;
    }

    const content = await fs.readFile(filePath, "utf-8");
    const wasmPath = `/${filePath}`;

    createDirectory(Module, path.dirname(wasmPath));
    Module.FS.writeFile(wasmPath, content);
  }
}

function createDirectory(Module, directory) {
  const parts = directory.split("/").filter(Boolean);
  let current = "";

  for (const part of parts) {
    current += `/${part}`;

    try {
      Module.FS.mkdir(current);
    } catch (error) {
      // Ignore EEXIST
    }
  }
}

async function runPicoRubyUntilResult(Module, getResult) {
  const timeoutMs = 10_000;
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeoutMs) {
    Module._mrb_tick_wasm();

    for (let i = 0; i < 1_000; i++) {
      const result = Module._mrb_run_step();

      if (result < 0) {
        throw new Error(`mrb_run_step returned ${result}`);
      }

      const testResult = getResult();
      if (testResult) {
        return testResult;
      }
    }

    await new Promise(resolve => setTimeout(resolve, 0));
  }

  throw new Error("PicoRuby unit tests did not finish.");
}

main().catch(err => {
  console.error(`❌ Test failed: ${err.message}`);
  process.exit(1);
});
