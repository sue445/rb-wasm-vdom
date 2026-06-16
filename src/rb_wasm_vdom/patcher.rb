# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  module Patcher
    # @rbs parent_el: untyped
    # @rbs old_vnode: VNode | String | nil
    # @rbs new_vnode: VNode | String | nil
    # @rbs index: Integer
    # @rbs return: void
    def patch(parent_el, old_vnode, new_vnode, index)
      current_el = child_at(parent_el, index)

      return append_node(parent_el, new_vnode) if old_vnode.nil?
      return remove_node(parent_el, current_el) if new_vnode.nil?
      return replace_node(parent_el, current_el, new_vnode) if changed?(old_vnode, new_vnode)

      patch_element(current_el, old_vnode, new_vnode) if both_elements?(old_vnode, new_vnode)
    end

    private

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

    # @rbs parent_el: untyped
    # @rbs index: Integer
    # @rbs return: untyped
    def child_at(parent_el, index)
      parent_el[:childNodes].item(index)
    end

    # @rbs parent_el: untyped
    # @rbs new_vnode: VNode | String | nil
    # @rbs return: void
    def append_node(parent_el, new_vnode)
      parent_el.appendChild(create_element(new_vnode)) if new_vnode
    end

    # @rbs parent_el: untyped
    # @rbs current_el: untyped
    # @rbs return: void
    def remove_node(parent_el, current_el)
      parent_el.removeChild(current_el) unless current_el == JS::Null
    end

    # @rbs parent_el: untyped
    # @rbs current_el: untyped
    # @rbs new_vnode: VNode | String
    # @rbs return: void
    def replace_node(parent_el, current_el, new_vnode)
      parent_el.replaceChild(create_element(new_vnode), current_el)
    end

    # @rbs old_vnode: VNode | String
    # @rbs new_vnode: VNode | String
    # @rbs return: bool
    def both_elements?(old_vnode, new_vnode)
      old_vnode.is_a?(VNode) && new_vnode.is_a?(VNode)
    end

    # @rbs current_el: untyped
    # @rbs old_vnode: VNode
    # @rbs new_vnode: VNode
    # @rbs return: void
    def patch_element(current_el, old_vnode, new_vnode)
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

      return unless new_children.length > old_children.length

      (old_children.length...new_children.length).each do |i|
        current_el.appendChild(create_element(new_children[i]))
      end
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
            el.addEventListener(event_name) do |e|
              @methods[v.to_sym].call(e, @state)
            end
          end
        elsif k == "value"
          el[:value] = v
          el.setAttribute(k, v)
        else
          el.setAttribute(k, v)
        end
      end
    end
  end
end
