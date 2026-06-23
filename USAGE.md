# Usage

## `RbWasmVdom.create_app`

Use `RbWasmVdom.create_app` to create and mount an application.

```ruby
RbWasmVdom.create_app(selector, template: template, state: state, methods: methods)
```

Arguments:

- `selector` — A CSS selector string for the mount target.
- [`template`](#template) — An HTML template string.
- [`state`](#state) — A Hash that defines the initial reactive state.
- [`methods`](#methods) — A Hash that defines event handler methods.

Example:

```ruby
template = <<~HTML
  <div>
    <p>Count: {{ count }}</p>
    <button @click="increment">Increment</button>
  </div>
HTML

state = {
  count: 0
}

methods = {
  increment: ->(event, state) {
    state[:count] += 1
  }
}

RbWasmVdom.create_app("#app", template: template, state: state, methods: methods)
```

## Template

The template is an HTML string used to describe the UI.

The template must have a single root element. If multiple root elements are provided, only the first element will be rendered.

A template can contain:

* Normal HTML elements
* Text nodes
* Attributes
* [State interpolation](#state-interpolation) with `{{ key }}`
* [List Rendering](#list-rendering) with `#each="item in items"` (`Array`), `#each="item, index in items"` (`Array`) or `#each="key, value in hash"` (`Hash`)
* [Event bindings](#event-binding) with `@event="method_name"`

Example:

```ruby
template = <<~HTML
  <div class="counter">
    <h2>{{ title }}</h2>
    <p>Count: {{ count }}</p>
    <button @click="increment">Increment</button>
  </div>
HTML
```

## State interpolation

Use `{{ key }}` to insert a value from the state into text or attributes.

```html
<p>{{ message }}</p>
<input value="{{ name }}">
```

The key inside `{{ }}` refers to a Symbol key in the state Hash.

```ruby
state = {
  message: "Hello",
  name: "Ruby"
}
```

Interpolation also supports nested values and public method calls.

```html
<p>{{ user.name }}</p>
<p>{{ user[:name] }}</p>
<p>{{ user.name.upcase }}</p>
<p>{{ user.name.gsub("R", "L") }}</p>
<p>{{ user.name.include?("R") }}</p>
<p>{{ user.name.slice(0, 2) }}</p>
```

For nested values, rb-wasm-vdom resolves Hash keys first, then calls public methods.

```ruby
state = {
  user: {
    name: "Ruby"
  }
}
```

The examples above render values such as:

```html
<p>Ruby</p>
<p>Ruby</p>
<p>RUBY</p>
<p>Luby</p>
<p>true</p>
<p>Ru</p>
```

Method arguments can be strings, integers, floats, booleans, or `nil`.

```html
<p>{{ user.name.gsub("Ruby", "Wasm") }}</p>
<p>{{ user.name.slice(0, 2) }}</p>
```

If an expression cannot be resolved or a method call raises an error, the original placeholder is left unchanged.

```html
<p>{{ user.unknown_value }}</p>
```

Because interpolation can call public methods, use templates you trust.

## List Rendering

Use `#each` to render a list from an Array or Hash in the state.

`#each` is an rb-wasm-vdom directive. It is used only for rendering and is not added to the final DOM element.

### Array rendering

Use `item in items` to render each item in an Array.

```ruby
template = <<~HTML
  <div>
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

RbWasmVdom.create_app("#app", template: template, state: state)
```

This renders one `<li>` element for each item in `items`.

```html
<ul>
  <li>Buy milk</li>
  <li>Write Ruby</li>
  <li>Ship wasm app</li>
</ul>
```

### Array rendering with index

Use `item, index in items` to access both the item and its index.

```ruby
template = <<~HTML
  <div>
    <h2>{{ title }}</h2>
    <ul>
      <li #each="item, index in items">{{ index }}: {{ item }}</li>
    </ul>
  </div>
HTML

state = {
  title: "Languages",
  items: ["Ruby", "Wasm", "VDOM"]
}

RbWasmVdom.create_app("#app", template: template, state: state)
```

This renders:

```html
<ul>
  <li>0: Ruby</li>
  <li>1: Wasm</li>
  <li>2: VDOM</li>
</ul>
```

### Hash rendering

Use `key, value in hash` to render each key-value pair in a Hash.

The order follows Ruby's `Hash#each` style: key first, value second.

```ruby
template = <<~HTML
  <div>
    <h2>{{ title }}</h2>
    <ul>
      <li #each="name, score in scores">{{ name }}: {{ score }}</li>
    </ul>
  </div>
HTML

state = {
  title: "Scores",
  scores: {
    alice: 90,
    bob: 75,
    carol: 88
  }
}

RbWasmVdom.create_app("#app", template: template, state: state)
```

This renders:

```html
<ul>
  <li>alice: 90</li>
  <li>bob: 75</li>
  <li>carol: 88</li>
</ul>
```

### Supported syntax

Currently, `#each` supports the following forms:

```html
<li #each="item in items">{{ item }}</li>
```

```html
<li #each="item, index in items">{{ index }}: {{ item }}</li>
```

```html
<li #each="key, value in scores">{{ key }}: {{ value }}</li>
```

The collection name must refer to a Symbol key in the state Hash.

```ruby
state = {
  items: ["Ruby", "Wasm"],
  scores: { alice: 90 }
}
```

## Event binding

Use attributes in the form `@event="method_name"` to bind DOM events to methods.

```html
<button @click="increment">Increment</button>
<input @input="update_name">
```

The value must match a key in the `methods` Hash.

## State

The state is a Ruby Hash passed to `create_app`.

```ruby
state = {
  title: "Counter App",
  count: 0,
  step: 1
}
```

State keys should be Symbols.

Inside methods, the state is passed as the second argument. You can read and write state values using `[]` and `[]=`.

```ruby
methods = {
  increment: ->(event, state) {
    state[:count] += 1
  }
}
```

When a state value is changed, rb-wasm-vdom re-renders the UI automatically.

If the assigned value is the same as the current value, no re-render is triggered.

## Methods

Methods are defined as a Ruby Hash.

```ruby
methods = {
  increment: ->(event, state) {
    state[:count] += 1
  },

  reset: ->(event, state) {
    state[:count] = 0
  }
}
```

Each method:

* Is registered with a Symbol key
* Is called from the template using an event binding
* Receives two arguments:
  * `event` — The DOM event object
  * `state` — The reactive state object

Example with an input event:

```ruby
template = <<~HTML
  <div>
    <input value="{{ name }}" @input="update_name">
    <p>Hello, {{ name }}!</p>
  </div>
HTML

state = {
  name: "Ruby"
}

methods = {
  update_name: ->(event, state) {
    state[:name] = event[:target][:value]
  }
}
```
