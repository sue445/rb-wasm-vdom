// Import all Ruby files as raw strings
// The '?raw' suffix tells Vite to load the file contents as a string instead of executing it.
import vnodeRb from "./rb_wasm_vdom/vnode.rb?raw";
import reactiveStateRb from "./rb_wasm_vdom/reactive_state.rb?raw";
import templateParserRb from "./rb_wasm_vdom/template_parser.rb?raw";
import domRendererRb from "./rb_wasm_vdom/dom_renderer.rb?raw";
import patcherRb from "./rb_wasm_vdom/patcher.rb?raw";
import interpolatorRb from "./rb_wasm_vdom/interpolator.rb?raw";
import eachRendererRb from "./rb_wasm_vdom/each_renderer.rb?raw";
import appRb from "./rb_wasm_vdom/app.rb?raw";
import mainRb from "./rb_wasm_vdom.rb?raw";

// Concatenate the files in the correct dependency order
const frameworkRubyCode = [
  vnodeRb,
  reactiveStateRb,
  templateParserRb,
  domRendererRb,
  patcherRb,
  interpolatorRb,
  eachRendererRb,
  appRb,
  mainRb
].join("\n\n");

// Flag to ensure the Ruby framework code is only evaluated once
let isInitialized = false;

/**
 * Mounts the application to the Virtual DOM.
 * * @param {Object} vm - The initialized Ruby VM instance (ruby.wasm or picoruby.wasm)
 * @param {Object} options - Configuration object containing el, template, state, and methods
 */
export function createApp(vm, { el, template, state, methods }) {
  // Evaluate the framework code only on the first call
  if (!isInitialized) {
    vm.eval(frameworkRubyCode);
    isInitialized = true;
  }

  // Pass JavaScript objects (state and methods) to the Ruby environment
  // by temporarily storing them in the global window object.
  window.__rb_vdom_state = state;
  window.__rb_vdom_methods = methods;

  // Call the Ruby create_app method and pass the properties
  vm.eval(`
    state_hash = JS.global[:__rb_vdom_state]
    methods_hash = JS.global[:__rb_vdom_methods]
    
    RbWasmVdom.create_app("${el}", template: """${template}""", state: state_hash, methods: methods_hash)
  `);
}
