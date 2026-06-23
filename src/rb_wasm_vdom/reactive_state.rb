# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  # Reactive State Management
  class ReactiveState
    # @rbs initial_data: Hash[Symbol, untyped]
    # @rbs &on_change: () -> void
    # @rbs return: void
    def initialize(initial_data, &on_change)
      @data = initial_data
      @on_change = on_change
    end

    # @rbs key: Symbol
    # @rbs return: untyped
    def [](key)
      @data[key]
    end

    # @rbs return: Array[Symbol]
    def keys
      @data.keys
    end

    # @rbs key: Symbol
    # @rbs value: untyped
    # @rbs return: void
    def []=(key, value)
      return if @data[key] == value

      @data[key] = value
      @on_change.call
    end
  end
end
