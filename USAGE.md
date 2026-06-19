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
