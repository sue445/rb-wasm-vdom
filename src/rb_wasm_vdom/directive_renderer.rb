# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  module DirectiveRenderer # rubocop:disable Metrics/ModuleLength
    include ConditionalRenderer

    private

    # @rbs ast_node: VNode | String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_vdom_nodes(ast_node, locals = {})
      return [@interpolator.call(ast_node, locals)] if ast_node.is_a?(String)
      return [] unless conditional_node_renderable?(ast_node, locals)

      build_vdom_nodes_without_condition(ast_node, locals)
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
        rendered_nodes, index = build_child_nodes_at(children, index, locals)
        new_children.concat(rendered_nodes)
      end

      new_children
    end

    # @rbs children: Array[VNode | String]
    # @rbs index: Integer
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: [Array[VNode | String], Integer]
    def build_child_nodes_at(children, index, locals)
      child = children[index]

      return build_conditional_child_nodes(children, index, locals) if conditional_start_node?(child)

      [build_vdom_nodes(child, locals), index + 1]
    end

    # @rbs children: Array[VNode | String]
    # @rbs index: Integer
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: [Array[VNode | String], Integer]
    def build_conditional_child_nodes(children, index, locals)
      conditional_node, next_index = find_conditional_node(children, index, locals)
      return [[], next_index] unless conditional_node

      [build_vdom_nodes_without_condition(conditional_node, locals), next_index]
    end

    # @rbs ast_node: VNode
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_vdom_nodes_without_condition(ast_node, locals)
      each_expression = ast_node.props["#each"]
      return build_each_nodes(ast_node, each_expression, locals) if each_expression

      [build_single_vnode(ast_node, locals)]
    end

    # @rbs ast_node: VNode
    # @rbs expression: String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_each_nodes(ast_node, expression, locals)
      parsed = parse_each_expression(expression)
      return [build_single_vnode(ast_node, locals)] unless parsed

      first_name, second_name, collection_expression = parsed
      collection = evaluate_each_collection(collection_expression, locals)

      build_collection_nodes(ast_node, collection, first_name, second_name, locals)
    end

    # @rbs expression: String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: untyped
    def evaluate_each_collection(expression, locals)
      Interpolator::EvaluationContext.new(@state, locals).evaluate(expression)
    rescue Exception => e # rubocop:disable Lint/RescueException
      JSConsole.print_error(e)

      nil
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
      match = expression.match(/^\s*(\w+)\s+in\s+(.+?)\s*$/)
      return nil unless match

      value_name = match[1]
      collection_expression = match[2]
      return nil unless value_name && collection_expression

      [value_name, nil, collection_expression]
    end

    # @rbs expression: String
    # @rbs return: [String, String, String]?
    def parse_each_pair_expression(expression)
      match = expression.match(/^\s*(\w+)\s*,\s*(\w+)\s+in\s+(.+?)\s*$/)
      return nil unless match

      first_name = match[1]
      second_name = match[2]
      collection_expression = match[3]
      return nil unless first_name && second_name && collection_expression

      [first_name, second_name, collection_expression]
    end

    # @rbs ast_node: VNode
    # @rbs collection: untyped
    # @rbs first_name: String
    # @rbs second_name: String?
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_collection_nodes(ast_node, collection, first_name, second_name, locals)
      case collection
      when Hash
        build_hash_nodes(ast_node, collection, first_name, second_name, locals)
      when JS::Object
        build_js_object_nodes(ast_node, collection, first_name, second_name, locals)
      when Enumerable
        build_array_nodes(ast_node, collection, first_name, second_name, locals)
      else
        []
      end
    end

    # @rbs ast_node: VNode
    # @rbs collection: Enumerable[untyped]
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

    # @rbs ast_node: VNode
    # @rbs collection: JS::Object
    # @rbs item_name: String
    # @rbs index_name: String?
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_js_object_nodes(ast_node, collection, item_name, index_name, locals)
      nodes = [] #: Array[VNode | String]

      0.upto(collection[:length].to_i - 1) do |index|
        item = collection[index]
        item_locals = locals.merge(item_name.to_sym => item)
        item_locals[index_name.to_sym] = index if index_name

        nodes << build_single_vnode(ast_node, item_locals)
      end

      nodes
    end
  end
end
