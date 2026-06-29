# frozen_string_literal: true

# c.f. https://zenn.dev/tmtms/articles/202605-mysql-params-picoruby
TOPLEVEL_BINDING = binding unless Object.const_defined?(:TOPLEVEL_BINDING)
UNIT_TEST_DIR = respond_to?(:require_relative) ? File.dirname(__FILE__) : "/test/unit"

require "js"

module RequireRelativePatch
  def require_relative(path)
    @loaded ||= {}
    @path ||= [UNIT_TEST_DIR]

    path = "#{path}.rb" unless path.end_with?(".rb")
    file_path = File.expand_path(path, @path.last)

    return if @loaded[file_path]

    @loaded[file_path] = true
    @path.push(File.dirname(file_path))

    TOPLEVEL_BINDING.eval(File.read(file_path))
  ensure
    @path.pop if @path && @path.length > 1
  end
end

# require_relative doesn't exist in PicoRuby.wasm
unless respond_to?(:require_relative)
  module Kernel
    prepend RequireRelativePatch
  end
end

test_files =
  if Object.const_defined?(:RB_WASM_VDOM_UNIT_TEST_FILES)
    RB_WASM_VDOM_UNIT_TEST_FILES
  else
    Dir.glob("#{UNIT_TEST_DIR}/*_test.rb")
  end

require_relative "support/simple_test_case"

test_files.each do |file|
  filename = File.basename(file)
  require_relative filename
end

# Test runner execution logic
success_count = 0
failure_count = 0

puts "\n🏃 Running Custom Ruby WASM Test Suite..."

SimpleTestCase.subclasses.each do |test_class|
  # Find all methods starting with 'test_'
  test_methods = test_class.instance_methods.select { |m| m.to_s.start_with?("test_") }

  test_methods.each do |method|
    instance = test_class.new
    begin
      instance.send(method)
      print "."
      success_count += 1
    rescue StandardError => e
      puts "\n❌ #{test_class}##{method} failed:"
      puts "  #{e.message}"
      failure_count += 1
    end
  end
end

puts "\n\n📊 Test Results:"
puts "  Passed: #{success_count}"
puts "  Failed: #{failure_count}"
puts "__RB_WASM_VDOM_UNIT_TEST_RESULT__:#{success_count}:#{failure_count}"

# Exit with non-zero code if any test failed
exit(1) if failure_count > 0
