begin
  template = <<~HTML
    <div class="app-container">
      <h2>{{ title }}</h2>
      <ul>
        <li #each="item, index in items">{{ index }}: {{ item }}</li>
      </ul>
    </div>
  HTML

  state = {
    title: "rb-wasm-vdom Example App (Array with Index Rendering)",
    items: ["Ruby", "Wasm", "VDOM"]
  }

  # Initialize and mount the application
  RbWasmVdom.create_app("#app", template: template, state: state)

rescue Exception => e
  message = "#{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}"
  JS.global[:console].error(message)
end
