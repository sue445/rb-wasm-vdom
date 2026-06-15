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

# Base class for all test cases
class SimpleTestCase
  include MiniTestMock

  def self.inherited(subclass)
    @subclasses ||= []
    @subclasses << subclass
  end

  def self.subclasses
    @subclasses || []
  end
end

# Automatically find and require all *_test.rb files in the test directory
# Exclude subdirectories by searching directly inside "./test"
Dir.glob("./test/unit/*_test.rb").each do |file|
  require file
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

# Exit with non-zero code if any test failed
exit(1) if failure_count > 0
