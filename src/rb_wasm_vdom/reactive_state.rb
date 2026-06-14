module RbWasmVdom
  # Reactive State Management
  class ReactiveState
    def initialize(initial_data, &on_change)
      @data = initial_data
      @on_change = on_change
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      return if @data[key] == value
      @data[key] = value
      @on_change.call
    end
  end
end
