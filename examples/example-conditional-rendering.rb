begin
  # Define the template with variable interpolation and event bindings
  template = <<~HTML
    <div class="app-container">
      <h2 style="margin-top: 0; color: #cc342d;">{{ title }}</h2>

      <div style="margin-bottom: 15px;">
        <label>Step value: </label>
        <input type="number" class="input-box" value="{{ count }}" @input="update_count">
      </div>

      <div>
        <p #if="count > 0">positive: {{ count }}</p>
        <p #elsif="count < 0">negative: {{ count }}</p>
        <p #else>zero</p>
      </div>
    </div>
  HTML

  # Define the reactive state
  state = {
    title: "rb-wasm-vdom Example App (Conditional Rendering)",
    count: 0,
  }

  # Define the methods to handle events and mutate the state
  methods = {
    update_count: ->(e, s) { s[:count] = e[:target][:value].to_i }
  }

  # Initialize and mount the application
  RbWasmVdom.create_app("#app", template: template, state: state, methods: methods)

rescue Exception => e
  message = "#{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}"
  JS.global[:console].error(message)
end
