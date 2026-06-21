# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  class Interpolator
    PLACEHOLDER_PATTERN = /\{\{\s*\w+\s*\}\}/
    KEY_PATTERN = /\w+/

    # @rbs state: ReactiveState
    def initialize(state)
      @state = state
    end

    # @rbs text: String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: String
    def call(text, locals = {})
      text.to_s.gsub(PLACEHOLDER_PATTERN) do |placeholder|
        interpolate_placeholder(placeholder, locals)
      end
    end

    private

    # @rbs placeholder: String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: String
    def interpolate_placeholder(placeholder, locals)
      key = placeholder.match(KEY_PATTERN)&.[](0)
      return placeholder unless key

      symbol_key = key.to_sym
      return locals[symbol_key].to_s if locals.key?(symbol_key)

      @state[symbol_key].to_s
    end
  end
end
