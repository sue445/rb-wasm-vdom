# frozen_string_literal: true

require_relative "../../src/rb_wasm_vdom/reactive_state"
require_relative "../../src/rb_wasm_vdom/interpolator"

class InterpolatorTest < SimpleTestCase
  def test_interpolate_from_state
    state = RbWasmVdom::ReactiveState.new({ title: "Hello" }) {} # rubocop:disable Lint/EmptyBlock
    interpolator = RbWasmVdom::Interpolator.new(state)

    assert_equal "Title: Hello", interpolator.call("Title: {{ title }}")
  end

  def test_interpolate_from_locals
    state = RbWasmVdom::ReactiveState.new({}) {} # rubocop:disable Lint/EmptyBlock
    interpolator = RbWasmVdom::Interpolator.new(state)

    assert_equal "Item: Ruby", interpolator.call("Item: {{ item }}", { item: "Ruby" })
  end

  def test_locals_take_precedence_over_state
    state = RbWasmVdom::ReactiveState.new({ item: "State Item" }) {} # rubocop:disable Lint/EmptyBlock
    interpolator = RbWasmVdom::Interpolator.new(state)

    assert_equal "Item: Local Item", interpolator.call("Item: {{ item }}", { item: "Local Item" })
  end

  def test_interpolate_multiple_locals
    state = RbWasmVdom::ReactiveState.new({}) {} # rubocop:disable Lint/EmptyBlock
    interpolator = RbWasmVdom::Interpolator.new(state)

    result = interpolator.call(
      "{{ index }}: {{ item }}",
      {
        index: 1,
        item: "Wasm"
      }
    )

    assert_equal "1: Wasm", result
  end
end
