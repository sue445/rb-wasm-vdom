begin
  template = <<~HTML
    <div class="app-container">
      <h2>{{ title }}</h2>
      <ul>
        <li #each="item in items">{{ item }}</li>
      </ul>
    </div>
  HTML

  state = {
    title: "Todo List",
    items: ["Buy milk", "Write Ruby", "Ship wasm app"]
  }

  # Initialize and mount the application
  RbWasmVdom.create_app("#app", template: template, state: state)

rescue Exception => e
  message = "#{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}"
  JS.global[:console].error(message)
end
