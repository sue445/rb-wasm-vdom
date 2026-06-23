# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  class Interpolator
    IDENTIFIER_PATTERN = /^[a-z_]\w*$/

    # @rbs state: ReactiveState
    def initialize(state)
      @state = state
    end

    # @rbs text: String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: String
    def call(text, locals = {})
      interpolate_text(text.to_s, locals)
    end

    private

    # @rbs text: String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: String
    def interpolate_text(text, locals)
      result = +""
      index = 0

      while index < text.length
        range = interpolation_range(text, index)
        return result << text[index..].to_s unless range

        result << text[index...range.begin].to_s
        result << interpolate_range(text, range, locals)

        index = range.end + 1
      end

      result
    end

    # @rbs text: String
    # @rbs index: Integer
    # @rbs return: Range[Integer]?
    def interpolation_range(text, index)
      start_index = text.index("{{", index)
      return nil unless start_index

      end_index = text.index("}}", start_index + 2)
      return nil unless end_index

      start_index..(end_index + 1)
    end

    # @rbs text: String
    # @rbs range: Range[Integer]
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: String
    def interpolate_range(text, range, locals)
      placeholder = text[range].to_s
      expression = text[(range.begin + 2)...(range.end - 1)].to_s.strip

      interpolate_expression(expression, placeholder, locals)
    end

    # @rbs expression: String
    # @rbs placeholder: String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: String
    def interpolate_expression(expression, placeholder, locals)
      return placeholder if expression.empty?

      value = EvaluationContext.new(@state, locals).evaluate(expression)
      return placeholder if value.nil?

      value.to_s
    rescue Exception # rubocop:disable Lint/RescueException
      placeholder
    end

    class EvaluationContext
      # @rbs state: ReactiveState
      # @rbs locals: Hash[Symbol, untyped]
      # @rbs return: void
      def initialize(state, locals)
        @state = state
        @locals = locals
      end

      # @rbs expression: String
      # @rbs return: untyped
      def evaluate(expression)
        eval(evaluation_code(expression)) # rubocop:disable Security/Eval
      end

      # @rbs key: Symbol
      # @rbs return: untyped
      def fetch_value(key)
        return ValueProxy.wrap(@locals[key]) if @locals.key?(key)

        ValueProxy.wrap(@state[key])
      end

      private

      # @rbs expression: String
      # @rbs return: String
      def evaluation_code(expression)
        "#{local_variable_assignments}\n#{expression}"
      end

      # @rbs return: String
      def local_variable_assignments
        visible_keys.map do |key|
          "#{key} = fetch_value(:#{key})"
        end.join("\n")
      end

      # @rbs return: Array[Symbol]
      def visible_keys
        (@locals.keys + state_keys).uniq.select do |key|
          valid_identifier?(key)
        end
      end

      # @rbs return: Array[Symbol]
      def state_keys
        @state.respond_to?(:keys) ? @state.keys : []
      end

      # @rbs key: Symbol
      # @rbs return: bool
      def valid_identifier?(key)
        key.to_s.match?(IDENTIFIER_PATTERN)
      end
    end

    class ValueProxy
      # @rbs value: untyped
      # @rbs return: untyped
      def self.wrap(value)
        return value if value.nil? || value == true || value == false
        return value if value.is_a?(Numeric)
        return value if value.is_a?(String)

        new(value)
      end

      # @rbs value: untyped
      # @rbs return: void
      def initialize(value)
        @value = value
      end

      # @rbs key: Symbol | String | Integer
      # @rbs return: untyped
      def [](key)
        return self.class.wrap(@value[key]) if @value.respond_to?(:[])

        nil
      end

      # @rbs return: String
      def to_s
        @value.to_s
      end

      private

      # @rbs name: Symbol
      # @rbs args: Array[untyped]
      # @rbs return: untyped
      def method_missing(name, *)
        return self.class.wrap(@value[name]) if hash_key?(name)
        return self.class.wrap(@value[name.to_s]) if hash_key?(name.to_s)
        return self.class.wrap(@value.public_send(name, *)) if @value.respond_to?(name)

        super
      end

      # @rbs name: Symbol
      # @rbs include_private: bool
      # @rbs return: bool
      def respond_to_missing?(name, include_private = false)
        hash_key?(name) || hash_key?(name.to_s) || @value.respond_to?(name) || super
      end

      # @rbs key: Symbol | String
      # @rbs return: bool
      def hash_key?(key)
        @value.respond_to?(:key?) && @value.key?(key)
      end
    end
  end
end
