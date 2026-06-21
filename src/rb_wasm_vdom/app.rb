# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  # Framework Core
  class App
    include Patcher
    include EachRenderer

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
  end
end
