import fs from "fs/promises";
import path from "path";
import { WASI } from "wasi";

async function main() {
  // Get the VM type from command line arguments (default to "ruby-wasm-head")
  const vmType = process.argv[2] || "ruby-wasm-head";

  console.log(`🚀 Running tests with VM: ${vmType}`);

  const rubyWasmMatch = vmType.match(/^ruby-wasm-(head|\d+\.\d+)$/);

  if (vmType === "picoruby-wasm-latest") {
    await runWithPicoRuby();

  } else if (rubyWasmMatch) {
    const version = rubyWasmMatch[1];
    await runWithRubyWasm(version);

  } else {
    throw new Error(`Unsupported arg: ${vmType}`);
  }
}

async function runWithRubyWasm(version) {
  const jsPkgName = "@ruby/wasm-wasi";
  const wasmPath = `node_modules/@ruby/${version}-wasm-wasi/dist/ruby.wasm`;

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
    require "./test/unit/test_runner.rb"
  `);
}

async function runWithPicoRuby() {
  const { default: createModule } = await import("@picoruby/wasm-wasi/picoruby.js");
  const wasmBinary = await fs.readFile("node_modules/@picoruby/wasm-wasi/dist/picoruby.wasm");
  const originalFetch = globalThis.fetch;

  globalThis.fetch = async (resource, options) => {
    if (String(resource).endsWith("picoruby.wasm")) {
      return new Response(wasmBinary, {
        status: 200,
        headers: {
          "Content-Type": "application/wasm"
        }
      });
    }

    return originalFetch(resource, options);
  };

  let testResult = null;

  try {
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

    await mountRubyFiles(Module, "src");
    await mountRubyFiles(Module, "test/unit");

    const testFiles = await listRubyTestFiles("test/unit");

    const runnerCode = `
      begin
        puts "PicoRuby runner started"
        RB_WASM_VDOM_UNIT_TEST_FILES = ${JSON.stringify(testFiles.map(file => `/${file}`))}
        eval(File.read("/test/unit/test_runner.rb"))
      rescue Exception => e
        puts "PicoRuby runner failed before test result:"
        puts "#{e.class}: #{e.message}"
        puts e.backtrace.join("\\n") if e.respond_to?(:backtrace) && e.backtrace
        puts "__RB_WASM_VDOM_UNIT_TEST_RESULT__:0:1"
      end
    `;

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
  } finally {
    globalThis.fetch = originalFetch;
  }
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
