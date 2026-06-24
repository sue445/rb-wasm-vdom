begin
  template = <<~HTML
    <div class="app-container">
      <h2>{{ title }}</h2>
      <p id="gsub">{{ user[:name].gsub("R", "L") }}</p>
      <p id="include">{{ user[:name].include?("R") }}</p>
      <p id="slice">{{ user[:name].slice(0, 2) }}</p>
    </div>
  HTML

  state = {
    title: "rb-wasm-vdom Example App (Call methods in interpolator)",
    user: {
      name: "Ruby"
    }
  }

  # Initialize and mount the application
  RbWasmVdom.create_app("#app", template: template, state: state)

rescue Exception => e
  message = "#{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}"
  JS.global[:console].error(message)
end
