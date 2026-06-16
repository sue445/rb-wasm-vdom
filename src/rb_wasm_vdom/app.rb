# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  # Framework Core
  class App
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

    # @rbs el: untyped
    # @rbs old_props: Hash[String, String]
    # @rbs new_props: Hash[String, String]
    # @rbs return: void
    def update_props(el, old_props, new_props)
      old_props.each_key do |k|
        el.removeAttribute(k) unless new_props.key?(k) || k.start_with?("@")
      end

      new_props.each do |k, v|
        next if old_props[k] == v

        if k.start_with?("@")
          unless old_props.key?(k)
            event_name = k.sub(/^@/, "")
            handler = ->(e) { @methods[v.to_sym].call(e, @state) }
            el.addEventListener(event_name, handler)
          end
        elsif k == "value"
          el[:value] = v
          el.setAttribute(k, v)
        else
          el.setAttribute(k, v)
        end
      end
    end

    # @rbs parent_el: untyped
    # @rbs old_vnode: VNode | String | nil
    # @rbs new_vnode: VNode | String | nil
    # @rbs index: Integer
    # @rbs return: void
    def patch(parent_el, old_vnode, new_vnode, index)
      current_el = parent_el[:childNodes].item(index)

      if old_vnode.nil?
        parent_el.appendChild(create_element(new_vnode)) if new_vnode
      elsif new_vnode.nil?
        parent_el.removeChild(current_el) unless current_el == JS::Null
      elsif changed?(old_vnode, new_vnode)
        parent_el.replaceChild(create_element(new_vnode), current_el)
      elsif old_vnode.is_a?(VNode) && new_vnode.is_a?(VNode)
        update_props(current_el, old_vnode.props, new_vnode.props)

        old_children = old_vnode.children
        new_children = new_vnode.children

        if old_children.length > new_children.length
          (old_children.length - 1).downto(new_children.length) do |i|
            child_to_remove = current_el[:childNodes].item(i)
            current_el.removeChild(child_to_remove) unless child_to_remove == JS::Null
          end
        end

        [old_children.length, new_children.length].min.times do |i|
          patch(current_el, old_children[i], new_children[i], i)
        end

        if new_children.length > old_children.length
          (old_children.length...new_children.length).each do |i|
            current_el.appendChild(create_element(new_children[i]))
          end
        end
      end
    end

    # @rbs node1: VNode | String
    # @rbs node2: VNode | String
    # @rbs return: bool
    def changed?(node1, node2)
      return true if node1.class != node2.class
      return node1 != node2 if node1.is_a?(String)

      # @type var node1: VNode
      # @type var node2: VNode

      node1.tag != node2.tag
    end
  end
end
