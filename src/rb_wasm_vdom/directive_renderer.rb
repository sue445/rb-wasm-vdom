# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  module DirectiveRenderer
    private

    CONDITIONAL_DIRECTIVES = ["#if", "#elsif", "#else"].freeze

    # @rbs ast_node: VNode | String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_vdom_nodes(ast_node, locals = {})
      return [@interpolator.call(ast_node, locals)] if ast_node.is_a?(String)

      return [] if ast_node.props.key?("#elsif") || ast_node.props.key?("#else")

      return [] if ast_node.props.key?("#if") && !truthy_expression?(ast_node.props["#if"], locals)

      each_expression = ast_node.props["#each"]
      return build_each_nodes(ast_node, each_expression, locals) if each_expression

      [build_single_vnode(ast_node, locals)]
    end

    # @rbs ast_node: VNode
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: VNode
    def build_single_vnode(ast_node, locals)
      new_props = {} #: Hash[String, String]
      ast_node.props.each do |key, value|
        next if key == "#each"
        next if CONDITIONAL_DIRECTIVES.include?(key)

        new_props[key] = @interpolator.call(value, locals)
      end

      new_children = build_child_nodes(ast_node.children, locals)
      VNode.new(ast_node.tag, new_props, new_children)
    end

    # @rbs children: Array[VNode | String]
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_child_nodes(children, locals)
      new_children = [] #: Array[VNode | String]
      index = 0

      while index < children.length
        child = children[index]

        if conditional_start_node?(child)
          rendered_nodes, next_index = build_conditional_nodes(children, index, locals)
          rendered_nodes.each do |new_child|
            new_children << new_child
          end
          index = next_index
          next
        end

        build_vdom_nodes(child, locals).each do |new_child|
          new_children << new_child
        end

        index += 1
      end

      new_children
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
    # @rbs return: [Array[VNode | String], Integer]
    def build_conditional_nodes(children, start_index, locals)
      index = start_index

      while index < children.length
        child = children[index]
        break unless child.is_a?(VNode)

        if render_conditional_node?(child, locals)
          return [build_vdom_nodes_without_condition(child, locals), next_conditional_index(children, index + 1)]
        end

        index += 1
        break unless index < children.length && conditional_continuation_node?(children[index])
      end

      [[], index]
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

    # @rbs ast_node: VNode
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_vdom_nodes_without_condition(ast_node, locals)
      each_expression = ast_node.props["#each"]
      return build_each_nodes(ast_node, each_expression, locals) if each_expression

      [build_single_vnode(ast_node, locals)]
    end

    # @rbs expression: String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: bool
    def truthy_expression?(expression, locals)
      !!Interpolator::EvaluationContext.new(@state, locals).evaluate(expression)
    rescue Exception => e # rubocop:disable Lint/RescueException
      backtrace = e.backtrace || []
      JS.global[:console].error(([e.message] + backtrace).join("\n"))

      false
    end

    # @rbs ast_node: VNode
    # @rbs expression: String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_each_nodes(ast_node, expression, locals)
      parsed = parse_each_expression(expression)
      return [build_single_vnode(ast_node, locals)] unless parsed

      first_name, second_name, collection_name = parsed
      collection = @state[collection_name.to_sym]

      build_collection_nodes(ast_node, collection, first_name, second_name, locals)
    end

    # @rbs expression: String
    # @rbs return: [String, String?, String]?
    def parse_each_expression(expression)
      parse_each_single_value_expression(expression) ||
        parse_each_pair_expression(expression)
    end

    # @rbs expression: String
    # @rbs return: [String, nil, String]?
    def parse_each_single_value_expression(expression)
      match = expression.match(/^\s*(\w+)\s+in\s+(\w+)\s*$/)
      return nil unless match

      value_name = match[1]
      collection_name = match[2]
      return nil unless value_name && collection_name

      [value_name, nil, collection_name]
    end

    # @rbs expression: String
    # @rbs return: [String, String, String]?
    def parse_each_pair_expression(expression)
      match = expression.match(/^\s*(\w+)\s*,\s*(\w+)\s+in\s+(\w+)\s*$/)
      return nil unless match

      first_name = match[1]
      second_name = match[2]
      collection_name = match[3]
      return nil unless first_name && second_name && collection_name

      [first_name, second_name, collection_name]
    end

    # @rbs ast_node: VNode
    # @rbs collection: untyped
    # @rbs first_name: String
    # @rbs second_name: String?
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_collection_nodes(ast_node, collection, first_name, second_name, locals)
      case collection
      when Array
        build_array_nodes(ast_node, collection, first_name, second_name, locals)
      when Hash
        build_hash_nodes(ast_node, collection, first_name, second_name, locals)
      else
        []
      end
    end

    # @rbs ast_node: VNode
    # @rbs collection: Array[untyped]
    # @rbs item_name: String
    # @rbs index_name: String?
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_array_nodes(ast_node, collection, item_name, index_name, locals)
      nodes = [] #: Array[VNode | String]
      index = 0

      collection.each do |item|
        item_locals = locals.merge(item_name.to_sym => item)
        item_locals[index_name.to_sym] = index if index_name

        nodes << build_single_vnode(ast_node, item_locals)
        index += 1
      end

      nodes
    end

    # @rbs ast_node: VNode
    # @rbs collection: Hash[untyped, untyped]
    # @rbs key_name: String
    # @rbs value_name: String?
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_hash_nodes(ast_node, collection, key_name, value_name, locals)
      nodes = [] #: Array[VNode | String]

      collection.each do |key, value|
        item_locals = locals.merge(key_name.to_sym => key)
        item_locals[value_name.to_sym] = value if value_name

        nodes << build_single_vnode(ast_node, item_locals)
      end

      nodes
    end
  end
end
