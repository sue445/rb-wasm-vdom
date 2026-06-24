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

  def test_interpolate_public_method_with_string_arguments
    state = RbWasmVdom::ReactiveState.new({}) {} # rubocop:disable Lint/EmptyBlock
    interpolator = RbWasmVdom::Interpolator.new(state)

    result = interpolator.call(
      '{{ user[:name].gsub("R", "L") }}',
      { user: { name: "Ruby" } }
    )

    assert_equal "Luby", result
  end

  def test_interpolate_public_predicate_method_with_string_argument
    state = RbWasmVdom::ReactiveState.new({}) {} # rubocop:disable Lint/EmptyBlock
    interpolator = RbWasmVdom::Interpolator.new(state)

    result = interpolator.call(
      '{{ user[:name].include?("R") }}',
      { user: { name: "Ruby" } }
    )

    assert_equal "true", result
  end

  def test_interpolate_public_method_with_integer_arguments
    state = RbWasmVdom::ReactiveState.new({}) {} # rubocop:disable Lint/EmptyBlock
    interpolator = RbWasmVdom::Interpolator.new(state)

    result = interpolator.call(
      "{{ user[:name].slice(0, 2) }}",
      { user: { name: "Ruby" } }
    )

    assert_equal "Ru", result
  end
end
