# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  module DomRenderer
    private

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
      remove_old_props(el, old_props, new_props)
      apply_new_props(el, old_props, new_props)
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
