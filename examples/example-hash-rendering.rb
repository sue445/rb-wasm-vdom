begin
  template = <<~HTML
    <div class="app-container">
      <h2>{{ title }}</h2>
      <ul>
        <li #each="name, score in scores">{{ name }}: {{ score }}</li>
      </ul>
    </div>
  HTML

  state = {
    title: "rb-wasm-vdom Example App (Hash Rendering)",
    scores: {
      alice: 90,
      bob: 75,
      carol: 88
    }
  }

  # Initialize and mount the application
  RbWasmVdom.create_app("#app", template: template, state: state)

rescue Exception => e
  message = "#{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}"
  JS.global[:console].error(message)
end
