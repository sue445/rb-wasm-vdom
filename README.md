# rb-wasm-vdom
A reactive Virtual DOM library for [ruby.wasm](https://github.com/ruby/ruby.wasm) and [PicoRuby.wasm](https://www.npmjs.com/package/@picoruby/wasm-wasi)

[![NPM Version](https://img.shields.io/npm/v/%40sue445%2Frb-wasm-vdom)](https://www.npmjs.com/package/@sue445/rb-wasm-vdom)
[![](https://data.jsdelivr.com/v1/package/npm/@sue445/rb-wasm-vdom/badge)](https://www.jsdelivr.com/package/npm/@sue445/rb-wasm-vdom)
[![build](https://github.com/sue445/rb-wasm-vdom/actions/workflows/build.yml/badge.svg)](https://github.com/sue445/rb-wasm-vdom/actions/workflows/build.yml)

## Quick Start
```html
<!-- Using ruby.wasm -->
<script src="https://cdn.jsdelivr.net/npm/@ruby/head-wasm-wasi/dist/browser.script.iife.min.js"></script>

<!--
or using PicoRuby.wasm
<script src="https://cdn.jsdelivr.net/npm/@picoruby/wasm-wasi@latest/dist/init.iife.js"></script>
-->

<script type="text/ruby" src="https://cdn.jsdelivr.net/npm/@sue445/rb-wasm-vdom@latest/dist/rb-wasm-vdom.rb"></script>

<!--
or specific version
<script type="text/ruby" src="https://cdn.jsdelivr.net/npm/@sue445/rb-wasm-vdom@X.Y.Z/dist/rb-wasm-vdom.rb"></script>
-->

<div id="app"></div>

<script type="text/ruby">
  # Define the template with variable interpolation and event bindings
  template = <<~HTML
    <div class="app-container">
      <h2 style="margin-top: 0; color: #cc342d;">{{ title }}</h2>

      <div style="margin-bottom: 15px;">
        <label>Step value: </label>
        <input type="number" class="input-box" value="{{ step }}" @input="update_step">
      </div>

      <p style="font-size: 1.2rem;">Current Count: <strong>{{ count }}</strong></p>

      <button class="btn" @click="increment">+ Increment</button>
      <button class="btn" @click="decrement">- Decrement</button>
      <button class="btn" style="background: #666;" @click="reset">Reset</button>
    </div>
  HTML

  # Define the reactive state
  state = {
    title: "Ruby Reactivity App",
    count: 0,
    step: 1
  }

  # Define the methods to handle events and mutate the state
  methods = {
    increment:   ->(e, s) { s[:count] += s[:step] },
    decrement:   ->(e, s) { s[:count] -= s[:step] },
    reset:       ->(e, s) { s[:count] = 0 },
    update_step: ->(e, s) { s[:step] = e[:target][:value].to_i }
  }

  # Initialize and mount the application
  RbWasmVdom.create_app("#app", template: template, state: state, methods: methods)
</script>

```

## Examples

| Name                         | Source                                                                                      | Browse on ruby.wasm                                                                              | Browse on PicoRuby.wasm                                                                              |
|------------------------------|---------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| Reactivity App               | [example-reactivity.rb](examples/example-reactivity.rb)                                     | [See](https://sue445.github.io/rb-wasm-vdom/example-reactivity-ruby-wasm.html)                   | [See](https://sue445.github.io/rb-wasm-vdom/example-reactivity-picoruby-wasm.html)                   |
| Array Rendering              | [example-array-rendering.rb](examples/example-array-rendering.rb)                           | [See](https://sue445.github.io/rb-wasm-vdom/example-array-rendering-ruby-wasm.html)              | [See](https://sue445.github.io/rb-wasm-vdom/example-array-rendering-picoruby-wasm.html)              |
| Array with Index Rendering   | [example-array-with-index-rendering.rb](examples/example-array-with-index-rendering.rb)     | [See](https://sue445.github.io/rb-wasm-vdom/example-array-with-index-rendering-ruby-wasm.html)   | [See](https://sue445.github.io/rb-wasm-vdom/example-array-with-index-rendering-picoruby-wasm.html)   |
| Hash Rendering               | [example-hash-rendering.rb](examples/example-hash-rendering.rb)                             | [See](https://sue445.github.io/rb-wasm-vdom/example-hash-rendering-ruby-wasm.html)               | [See](https://sue445.github.io/rb-wasm-vdom/example-hash-rendering-picoruby-wasm.html)               |
| Call methods in interpolator | [example-call-methods-in-interpolator.rb](examples/example-call-methods-in-interpolator.rb) | [See](https://sue445.github.io/rb-wasm-vdom/example-call-methods-in-interpolator-ruby-wasm.html) | [See](https://sue445.github.io/rb-wasm-vdom/example-call-methods-in-interpolator-picoruby-wasm.html) |
| Conditional Rendering        | [example-conditional-rendering.rb](examples/example-conditional-rendering.rb)               | [See](https://sue445.github.io/rb-wasm-vdom/example-conditional-rendering-ruby-wasm.html)        | [See](https://sue445.github.io/rb-wasm-vdom/example-conditional-rendering-picoruby-wasm.html)        |
| Tic-Tac-Toe                  | [example-tic-tac-toe.rb](examples/example-tic-tac-toe.rb)                                   | [See](https://sue445.github.io/rb-wasm-vdom/example-tic-tac-toe-ruby-wasm.html)                  | [See](https://sue445.github.io/rb-wasm-vdom/example-tic-tac-toe-picoruby-wasm.html)                  |
| Multiple root                | [example-multiple-root.rb](examples/example-multiple-root.rb)                               | [See](https://sue445.github.io/rb-wasm-vdom/example-multiple-root-ruby-wasm.html)                | [See](https://sue445.github.io/rb-wasm-vdom/example-multiple-root-picoruby-wasm.html)                |

## Usage
For detailed usage, see [USAGE.md](USAGE.md).

## Development
### Run test
At first, install [wasmtime](https://docs.wasmtime.dev/cli-install.html)

e.g.

* Mac: `brew install wasmtime`

```bash
npm install
npx playwright install chromium
npm test
```
