require "js"
require "json"

module RbWasmVdom
  # Public API
  def self.create_app(selector, template:, state:, methods:)
    App.new(selector, template: template, state: state, methods: methods)
  end
end
