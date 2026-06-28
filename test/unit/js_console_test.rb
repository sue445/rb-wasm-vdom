# frozen_string_literal: true

require_relative "test_helper"

class JsConsoleTest < SimpleTestCase
  include JsStubHelper

  def test_print_error
    with_js_global_stub do |console|
      error = StandardError.new("Test error")
      RbWasmVdom::JSConsole.print_error(error)
      assert_equal 1, console.messages.length
      assert(console.messages[0].start_with?("StandardError: Test error"))
    end
  end
end
