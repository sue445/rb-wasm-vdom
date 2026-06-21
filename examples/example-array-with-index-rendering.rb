begin
  template = <<~HTML
    <ul>
      <li #each="item, index in items">{{ index }}: {{ item }}</li>
    </ul>
  HTML

  state = {
    items: ["Ruby", "Wasm", "VDOM"]
  }

  # Initialize and mount the application
  RbWasmVdom.create_app("#app", template: template, state: state)

rescue Exception => e
  message = "#{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}"
  JS.global[:console].error(message)
end
