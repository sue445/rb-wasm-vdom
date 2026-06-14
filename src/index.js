// src/index.js
import frameworkRubyCode from "./rb_wasm_vdom.rb?raw";

// Flag to determine if the framework code has already been evaluated
let isInitialized = false;

/**
 * Mounts the application
 * @param {Object} vm - Initialized ruby.wasm or picoruby.wasm VM instance
 * @param {Object} options - { el, template, state, methods }
 */
export function createApp(vm, { el, template, state, methods }) {
  // Evaluate the framework Ruby code and define classes only on the first run
  if (!isInitialized) {
    vm.eval(frameworkRubyCode);
    isInitialized = true;
  }

  // Pass JavaScript objects to Ruby via the global object
  window.__rb_vdom_state = state;
  window.__rb_vdom_methods = methods;

  // Call the create_app method on the Ruby side
  vm.eval(`
    state_hash = JS.global[:__rb_vdom_state]
    methods_hash = JS.global[:__rb_vdom_methods]
    
    RbWasmVdom.create_app("${el}", template: """${template}""", state: state_hash, methods: methods_hash)
  `);
}
