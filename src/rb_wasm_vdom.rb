# frozen_string_literal: true
# rbs_inline: enabled

require "js"
require "json"

require_relative "rb_wasm_vdom/app"

module RbWasmVdom
  # @rbs selector: String
  # @rbs template: String
  # @rbs state: Hash[Symbol, untyped]
  # @rbs methods: Hash[Symbol, Proc]
  # @rbs return: App
  def self.create_app(selector, template: "", state: {}, methods: {})
    App.new(selector, template: template, state: state, methods: methods)
  end
end
