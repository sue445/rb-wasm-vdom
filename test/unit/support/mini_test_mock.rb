# frozen_string_literal: true

# Simple custom assertion helpers compatible with both ruby.wasm and picoruby.wasm
module MiniTestMock
  def assert(condition, message = "Assertion failed")
    return if condition

    raise "Failure: #{message}"
  end

  def assert_equal(expected, actual, message = nil)
    return if expected == actual

    msg = message || "Expected #{expected.inspect}, but got #{actual.inspect}"
    raise "Failure: #{msg}"
  end
end
