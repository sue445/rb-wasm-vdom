template = <<~HTML
  <div class="app-container"></div>
  <h1>{{ title }}</h1>
HTML

state = {
  title: "rb-wasm-vdom Example App (Multiple root)",
}

RbWasmVdom.create_app("#app", template: template, state: state)
