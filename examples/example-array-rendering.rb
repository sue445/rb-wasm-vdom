begin
  template = <<~HTML
    <div class="app-container">
      <h2>{{ title }}</h2>
      <ul>
        <li #each="item in items">{{ item }}</li>
      </ul>
      <dl #each="user in users">
        <dt>Name</dt>
        <dd>{{ user[:name] }}</dd>
        <dt>Age</dt>
        <dd>{{ user[:age] }}</dd>
        <dt>Languages</dt>
        <dd>
          <ul>
            <li #each="language in user[:languages]">{{ language }}</li>
          </ul>
        </dd>
      </dl>
      <ul>
        <li #each="js_object in js_array">{{ js_object }}</li>
      </ul>
    </div>
  HTML

  JS.eval("globalThis.__RbWasmVdomExampleArray = [1, 2, 3]")

  state = {
    title: "rb-wasm-vdom Example App (Array Rendering)",
    items: ["Buy milk", "Write Ruby", "Ship wasm app"],
    users: [
      { name: "foo", age: 10, languages: ["Ruby", "Go"] },
      { name: "bar", age: 20, languages: ["TypeScript"] },
      { name: "baz", age: 30, languages: ["Rust"] },
    ],
    js_array: JS.global["__RbWasmVdomExampleArray"]
  }

  # Initialize and mount the application
  RbWasmVdom.create_app("#app", template: template, state: state)

rescue Exception => e
  message = "#{e.class}: #{e.message}\n#{e.backtrace&.join("\n")}"
  JS.global[:console].error(message)
end
