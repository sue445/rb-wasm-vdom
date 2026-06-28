# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  module ConditionalRenderer
    CONDITIONAL_DIRECTIVES = ["#if", "#elsif", "#else"].freeze

    private

    # @rbs ast_node: VNode
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: bool
    def conditional_node_renderable?(ast_node, locals)
      return false if ast_node.props.key?("#elsif") || ast_node.props.key?("#else")
      return true unless ast_node.props.key?("#if")

      truthy_expression?(ast_node.props["#if"], locals)
    end

    # @rbs child: VNode | String
    # @rbs return: bool
    def conditional_start_node?(child)
      child.is_a?(VNode) && child.props.key?("#if")
    end

    # @rbs child: VNode | String
    # @rbs return: bool
    def conditional_continuation_node?(child)
      child.is_a?(VNode) && (child.props.key?("#elsif") || child.props.key?("#else"))
    end

    # @rbs children: Array[VNode | String]
    # @rbs start_index: Integer
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: [VNode?, Integer]
    def find_conditional_node(children, start_index, locals)
      conditional_index = find_renderable_conditional_index(children, start_index, locals)
      next_index = next_conditional_index(children, start_index + 1)

      return [nil, next_index] unless conditional_index

      child = children[conditional_index]
      return [nil, next_index] unless child.is_a?(VNode)

      [child, next_index]
    end

    # @rbs children: Array[VNode | String]
    # @rbs start_index: Integer
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Integer?
    def find_renderable_conditional_index(children, start_index, locals)
      index = start_index

      while index < children.length
        child = children[index]
        break unless child.is_a?(VNode)
        return index if render_conditional_node?(child, locals)

        index += 1
        break unless index < children.length && conditional_continuation_node?(children[index])
      end

      nil
    end

    # @rbs children: Array[VNode | String]
    # @rbs index: Integer
    # @rbs return: Integer
    def next_conditional_index(children, index)
      index += 1 while index < children.length && conditional_continuation_node?(children[index])

      index
    end

    # @rbs ast_node: VNode
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: bool
    def render_conditional_node?(ast_node, locals)
      if ast_node.props.key?("#if")
        truthy_expression?(ast_node.props["#if"], locals)
      elsif ast_node.props.key?("#elsif")
        truthy_expression?(ast_node.props["#elsif"], locals)
      else
        ast_node.props.key?("#else")
      end
    end

    # @rbs expression: String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: bool
    def truthy_expression?(expression, locals)
      !!Interpolator::EvaluationContext.new(@state, locals).evaluate(expression)
    rescue Exception => e # rubocop:disable Lint/RescueException
      JSConsole.print_error(e)

      false
    end
  end
end
