# rb-wasm-vdom
A reactive Virtual DOM library for [ruby.wasm](https://github.com/ruby/ruby.wasm) and [Picoruby.wasm](https://www.npmjs.com/package/@picoruby/wasm-wasi)

[![NPM Version](https://img.shields.io/npm/v/%40sue445%2Frb-wasm-vdom)](https://www.npmjs.com/package/@sue445/rb-wasm-vdom)
[![build](https://github.com/sue445/rb-wasm-vdom/actions/workflows/build.yml/badge.svg)](https://github.com/sue445/rb-wasm-vdom/actions/workflows/build.yml)

## Development
### Run unit test
At first, install [wasmtime](https://docs.wasmtime.dev/cli-install.html)

* Mac: `brew install wasmtime`

```bash
npm run test:unit
```

### Run integration test
```bash
npx playwright install
npm run test:integration
```
