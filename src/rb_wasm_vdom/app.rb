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

    # @rbs text: VNode | String
    # @rbs return: String
    def interpolate(text)
      text.to_s.gsub(/\{\{\s*\w+\s*\}\}/) do |inside_bracket|
        matched = inside_bracket.match(/\w+/)

        matched_str = matched&.[](0)
        if matched_str
          key = matched_str.to_sym
          @state[key].to_s
        else
          inside_bracket
        end
      end
    end

    # @rbs ast_node: VNode | String
    # @rbs return: VNode | String
    def build_vdom(ast_node)
      return interpolate(ast_node) if ast_node.is_a?(String)

      new_props = {} #: Hash[String, String]
      ast_node.props.each do |k, v|
        new_props[k] = interpolate(v)
      end

      new_children = ast_node.children.map { |child| build_vdom(child) }
      VNode.new(ast_node.tag, new_props, new_children)
    end

    # @rbs vnode: VNode | String
    # @rbs return: untyped
    def create_element(vnode)
      document = JS.global[:document]
      return document.createTextNode(vnode) if vnode.is_a?(String)

      el = document.createElement(vnode.tag)
      update_props(el, {}, vnode.props)

      vnode.children.each do |child|
        el.appendChild(create_element(child))
      end
      el
    end
  end
end
