# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  # Framework Core
  class App
    include Patcher

    # @rbs selector: String
    # @rbs template: String
    # @rbs state: Hash[Symbol, untyped]
    # @rbs methods: Hash[Symbol, Proc]
    # @rbs return: void
    def initialize(selector, template:, state:, methods:)
      @el = JS.global[:document].querySelector(selector)
      @template_ast = TemplateParser.parse(template)
      @methods = methods
      @current_vnode = nil

      @state = ReactiveState.new(state) do
        render_cycle
      end

      @interpolator = Interpolator.new(@state)

      render_cycle
    end

    private

    # @rbs return: void
    def render_cycle
      new_vnode = build_vdom(@template_ast)

      if @current_vnode.nil?
        @el[:innerHTML] = ""
        @el.appendChild(create_element(new_vnode))
      else
        patch(@el, @current_vnode, new_vnode, 0)
      end

      @current_vnode = new_vnode
    end

    # @rbs ast_node: VNode | String
    # @rbs return: VNode | String
    def build_vdom(ast_node)
      build_vdom_nodes(ast_node).first
    end

    # @rbs ast_node: VNode | String
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_vdom_nodes(ast_node, locals = {})
      return [@interpolator.call(ast_node, locals)] if ast_node.is_a?(String)

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

      children.each do |child|
        build_vdom_nodes(child, locals).each do |new_child|
          new_children << new_child
        end
      end

      new_children
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
      return [::Regexp.last_match(1), nil, ::Regexp.last_match(2)] if expression =~ /\A\s*(\w+)\s+in\s+(\w+)\s*\z/

      return [::Regexp.last_match(1), ::Regexp.last_match(2),
              ::Regexp.last_match(3)] if expression =~ /\A\s*(\w+)\s*,\s*(\w+)\s+in\s+(\w+)\s*\z/

      nil
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
      collection.each_with_index.map do |item, index|
        item_locals = locals.merge(item_name.to_sym => item)
        item_locals[index_name.to_sym] = index if index_name

        build_single_vnode(ast_node, item_locals)
      end
    end

    # @rbs ast_node: VNode
    # @rbs collection: Hash[untyped, untyped]
    # @rbs key_name: String
    # @rbs value_name: String?
    # @rbs locals: Hash[Symbol, untyped]
    # @rbs return: Array[VNode | String]
    def build_hash_nodes(ast_node, collection, key_name, value_name, locals)
      collection.map do |key, value|
        item_locals = locals.merge(key_name.to_sym => key)
        item_locals[value_name.to_sym] = value if value_name

        build_single_vnode(ast_node, item_locals)
      end
    end
  end
end
