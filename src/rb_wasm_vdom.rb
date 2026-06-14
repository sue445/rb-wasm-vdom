require "js"
require "json"

module RbWasmVdom
  # ==========================================
  # Virtual DOM Node Definition
  # ==========================================
  class VNode
    attr_reader :tag, :props, :children

    def initialize(tag, props = {}, children = [])
      @tag = tag
      @props = props
      @children = children
    end
  end

  # ==========================================
  # Reactive State Management
  # ==========================================
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

  # ==========================================
  # HTML Template Parser
  # ==========================================
  class TemplateParser
    def self.setup_js_parser
      # Add a prefix to the function name to prevent global namespace pollution in JS
      JS.eval(<<~JS)
        window.__RbWasmVdom_parseHTMLToJSON = function(html) {
          const doc = new DOMParser().parseFromString(html, "text/html");
          function walk(node) {
            if (node.nodeType === 3) {
              const text = node.textContent.trim();
              return text ? text : null;
            }
            if (node.nodeType === 1) {
              const obj = { tag: node.tagName.toLowerCase(), props: {}, children: [] };
              for (let i = 0; i < node.attributes.length; i++) {
                obj.props[node.attributes[i].name] = node.attributes[i].value;
              }
              for (let i = 0; i < node.childNodes.length; i++) {
                const childRes = walk(node.childNodes[i]);
                if (childRes !== null) obj.children.push(childRes);
              }
              return obj;
            }
            return null;
          }
          const root = doc.body.firstElementChild;
          return root ? JSON.stringify(walk(root)) : "null";
        }
      JS
      @setup_done = true
    end

    def self.parse(html_string)
      setup_js_parser unless @setup_done
      json_str = JS.global.__RbWasmVdom_parseHTMLToJSON(html_string).to_s
      return nil if json_str == "null" || json_str.empty?
      build_ast(JSON.parse(json_str))
    end

    def self.build_ast(data)
      return data if data.is_a?(String)
      children = data["children"].map { |child| build_ast(child) }
      VNode.new(data["tag"], data["props"], children)
    end
  end

  # ==========================================
  # Framework Core
  # ==========================================
  class App
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

    def interpolate(text)
      text.to_s.gsub(/\{\{\s*(\w+)\s*\}\}/) { @state[$1.to_sym].to_s }
    end

    def build_vdom(ast_node)
      return interpolate(ast_node) if ast_node.is_a?(String)

      new_props = {}
      ast_node.props.each do |k, v|
        new_props[k] = interpolate(v)
      end

      new_children = ast_node.children.map { |child| build_vdom(child) }
      VNode.new(ast_node.tag, new_props, new_children)
    end

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

    def patch(parent_el, old_vnode, new_vnode, index)
      current_el = parent_el[:childNodes].item(index)

      if old_vnode.nil?
        parent_el.appendChild(create_element(new_vnode))
      elsif new_vnode.nil?
        parent_el.removeChild(current_el) unless current_el == JS::Null
      elsif changed?(old_vnode, new_vnode)
        parent_el.replaceChild(create_element(new_vnode), current_el)
      elsif new_vnode.is_a?(VNode)
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

    def changed?(node1, node2)
      return true if node1.class != node2.class
      return node1 != node2 if node1.is_a?(String)
      node1.tag != node2.tag
    end
  end

  # ==========================================
  # Public API
  # ==========================================
  def self.create_app(selector, template:, state:, methods:)
    App.new(selector, template: template, state: state, methods: methods)
  end
end
