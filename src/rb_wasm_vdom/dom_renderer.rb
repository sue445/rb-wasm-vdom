# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  module DomRenderer
    private

    # @rbs vnode: VNode | VFragment | String
    # @rbs return: untyped
    def create_element(vnode)
      document = JS.global[:document]
      return document.createTextNode(vnode) if vnode.is_a?(String)

      return create_fragment_element(document, vnode) if vnode.is_a?(VFragment)

      create_node_element(document, vnode)
    end

    # @rbs el: untyped
    # @rbs old_props: Hash[String, String]
    # @rbs new_props: Hash[String, String]
    # @rbs return: void
    def update_props(el, old_props, new_props)
      remove_old_props(el, old_props, new_props)
      apply_new_props(el, old_props, new_props)
    end

    # @rbs document: untyped
    # @rbs fragment: VFragment
    # @rbs return: untyped
    def create_fragment_element(document, fragment)
      element = document.createDocumentFragment
      append_children(element, fragment.children)
      element
    end

    # @rbs document: untyped
    # @rbs vnode: VNode
    # @rbs return: untyped
    def create_node_element(document, vnode)
      el = document.createElement(vnode.tag)
      update_props(el, {}, vnode.props)
      append_children(el, vnode.children)
      el
    end

    # @rbs el: untyped
    # @rbs children: Array[VNode | VFragment | String]
    # @rbs return: void
    def append_children(el, children)
      children.each do |child|
        el.appendChild(create_element(child))
      end
    end

    # @rbs el: untyped
    # @rbs old_props: Hash[String, String]
    # @rbs new_props: Hash[String, String]
    # @rbs return: void
    def remove_old_props(el, old_props, new_props)
      old_props.each_key do |key|
        el.removeAttribute(key) unless new_props.key?(key) || key.start_with?("@")
      end
    end

    # @rbs el: untyped
    # @rbs old_props: Hash[String, String]
    # @rbs new_props: Hash[String, String]
    # @rbs return: void
    def apply_new_props(el, old_props, new_props)
      new_props.each do |key, value|
        next if old_props[key] == value

        apply_prop(el, old_props, key, value)
      end
    end

    # @rbs el: untyped
    # @rbs old_props: Hash[String, String]
    # @rbs key: String
    # @rbs value: String
    # @rbs return: void
    def apply_prop(el, old_props, key, value)
      if key.start_with?("@")
        add_event_listener(el, old_props, key, value)
      elsif key == "value"
        update_value_prop(el, key, value)
      else
        el.setAttribute(key, value)
      end
    end

    # @rbs el: untyped
    # @rbs old_props: Hash[String, String]
    # @rbs key: String
    # @rbs value: String
    # @rbs return: void
    def add_event_listener(el, old_props, key, value)
      return if old_props.key?(key)

      event_name = key.sub(/^@/, "")
      el.addEventListener(event_name) do |e|
        @methods[value.to_sym].call(e, @state)
      end
    end

    # @rbs el: untyped
    # @rbs key: String
    # @rbs value: String
    # @rbs return: void
    def update_value_prop(el, key, value)
      el[:value] = value
      el.setAttribute(key, value)
    end
  end
end
