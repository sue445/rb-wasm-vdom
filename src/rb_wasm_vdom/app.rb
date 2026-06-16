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
      return @interpolator.call(ast_node) if ast_node.is_a?(String)

      new_props = {} #: Hash[String, String]
      ast_node.props.each do |k, v|
        new_props[k] = @interpolator.call(v)
      end

      new_children = ast_node.children.map { |child| build_vdom(child) }
      VNode.new(ast_node.tag, new_props, new_children)
    end
  end
end
