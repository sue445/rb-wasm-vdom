# frozen_string_literal: true

module JsStubHelper
  # @rbs json: String
  # @rbs return: JS::Object
  def js_array(json)
    # rubocop:disable Style/DocumentDynamicEvalDefinition
    JS.eval("globalThis.__RbWasmVdomTestArray = #{json}")
    # rubocop:enable Style/DocumentDynamicEvalDefinition

    JS.global["__RbWasmVdomTestArray"]
  end

  def with_js_global_stub
    console = ConsoleErrorSpy.new
    global = JsGlobalStub.new(console)

    js_was_defined = Object.const_defined?(:JS)
    Object.const_set(:JS, Module.new) unless js_was_defined

    original_global = JS.method(:global) if JS.respond_to?(:global)
    JS.define_singleton_method(:global) { global }

    yield console
  ensure
    if original_global
      JS.define_singleton_method(:global) { original_global.call }
    elsif js_was_defined
      JS.singleton_class.remove_method(:global) if JS.respond_to?(:global)
    else
      Object.send(:remove_const, :JS)
    end
  end

  class ConsoleErrorSpy
    attr_reader :messages

    def initialize
      @messages = []
    end

    def error(message)
      @messages << message
    end
  end

  class JsGlobalStub
    def initialize(console)
      @console = console
    end

    def [](key)
      return @console if key == :console

      nil
    end
  end
end
