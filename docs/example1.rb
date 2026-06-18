begin
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

rescue Exception => e
  message = "#{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}"
  JS.global[:console].error(message)
end
