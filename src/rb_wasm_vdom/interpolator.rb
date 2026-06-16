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
    def call(text)
      text.to_s.gsub(PLACEHOLDER_PATTERN) do |placeholder|
        interpolate_placeholder(placeholder)
      end
    end

    private

    # @rbs placeholder: String
    # @rbs return: String
    def interpolate_placeholder(placeholder)
      key = placeholder.match(KEY_PATTERN)&.[](0)
      return placeholder unless key

      @state[key.to_sym].to_s
    end
  end
end
