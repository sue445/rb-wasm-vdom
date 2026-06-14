require "minitest/autorun"
require_relative "../src/rb_wasm_vdom/reactive_state"

class ReactiveStateTest < Minitest::Test
  # Test that the initial state can be read correctly
  def test_read_state
    state = RbWasmVdom::ReactiveState.new({ count: 0, title: "Test" }) {}

    assert_equal 0, state[:count]
    assert_equal "Test", state[:title]
  end

  # Test that writing a new value updates the state and triggers the callback
  def test_write_state_triggers_callback
    callback_triggered = false

    state = RbWasmVdom::ReactiveState.new({ count: 0 }) do
      callback_triggered = true
    end

    state[:count] = 1

    assert_equal 1, state[:count]
    assert callback_triggered
  end

  # Test that writing the exact same value does NOT trigger the callback
  def test_write_same_value_ignores_callback
    callback_triggered = false

    state = RbWasmVdom::ReactiveState.new({ count: 0 }) do
      callback_triggered = true
    end

    state[:count] = 0

    assert_equal 0, state[:count]
    refute callback_triggered
  end
end
