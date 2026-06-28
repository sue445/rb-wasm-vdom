# frozen_string_literal: true

require_relative "mini_test_mock"

# Base class for all test cases
class SimpleTestCase
  include MiniTestMock

  def self.inherited(subclass)
    super
    @subclasses ||= []
    @subclasses << subclass
  end

  def self.subclasses
    @subclasses || []
  end
end
