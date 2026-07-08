# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  module Patcher
    include DomRenderer

    # @rbs parent_el: untyped
    # @rbs old_vnode: VNode | VFragment | String | nil
    # @rbs new_vnode: VNode | VFragment | String | nil
    # @rbs index: Integer
    # @rbs return: void
    def patch(parent_el, old_vnode, new_vnode, index)
      current_el = child_at(parent_el, index)

      return append_node(parent_el, new_vnode) if old_vnode.nil?
      return remove_node(parent_el, current_el) if new_vnode.nil?
      return replace_node(parent_el, current_el, new_vnode) if changed?(old_vnode, new_vnode)

      patch_existing_node(parent_el, current_el, old_vnode, new_vnode)
    end

    # @rbs parent_el: untyped
    # @rbs old_fragment: VFragment
    # @rbs new_fragment: VFragment
    # @rbs return: void
    def patch_fragment(parent_el, old_fragment, new_fragment)
      patch_children(parent_el, old_fragment.children, new_fragment.children)
    end

    private

    # @rbs parent_el: untyped
    # @rbs current_el: untyped
    # @rbs old_vnode: VNode | VFragment | String
    # @rbs new_vnode: VNode | VFragment | String
    # @rbs return: void
    def patch_existing_node(parent_el, current_el, old_vnode, new_vnode)
      if old_vnode.is_a?(VNode) && new_vnode.is_a?(VNode)
        patch_element(current_el, old_vnode, new_vnode)
      elsif old_vnode.is_a?(VFragment) && new_vnode.is_a?(VFragment)
        patch_fragment(parent_el, old_vnode, new_vnode)
      end
    end

    # @rbs parent_el: untyped
    # @rbs index: Integer
    # @rbs return: untyped
    def child_at(parent_el, index)
      parent_el[:childNodes].item(index)
    end

    # @rbs node1: VNode | VFragment | String
    # @rbs node2: VNode | VFragment | String
    # @rbs return: bool
    def changed?(node1, node2)
      return true if node1.class != node2.class
      return node1 != node2 if node1.is_a?(String)
      return false if node1.is_a?(VFragment)

      # @type var node1: VNode
      # @type var node2: VNode

      node1.tag != node2.tag
    end

    # @rbs parent_el: untyped
    # @rbs new_vnode: VNode | VFragment | String | nil
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
    # @rbs new_vnode: VNode | VFragment | String
    # @rbs return: void
    def replace_node(parent_el, current_el, new_vnode)
      parent_el.replaceChild(create_element(new_vnode), current_el)
    end

    # @rbs current_el: untyped
    # @rbs old_vnode: VNode
    # @rbs new_vnode: VNode
    # @rbs return: void
    def patch_element(current_el, old_vnode, new_vnode)
      update_props(current_el, old_vnode.props, new_vnode.props)
      patch_children(current_el, old_vnode.children, new_vnode.children)
    end

    # @rbs current_el: untyped
    # @rbs old_children: Array[VNode | VFragment | String]
    # @rbs new_children: Array[VNode | VFragment | String]
    # @rbs return: void
    def patch_children(current_el, old_children, new_children)
      remove_extra_children(current_el, old_children, new_children)
      patch_common_children(current_el, old_children, new_children)

      return unless new_children.length > old_children.length

      append_missing_children(current_el, old_children, new_children)
    end

    # @rbs current_el: untyped
    # @rbs old_children: Array[VNode | VFragment | String]
    # @rbs new_children: Array[VNode | VFragment | String]
    # @rbs return: void
    def remove_extra_children(current_el, old_children, new_children)
      return unless old_children.length > new_children.length

      (old_children.length - 1).downto(new_children.length) do |i|
        child_to_remove = current_el[:childNodes].item(i)
        current_el.removeChild(child_to_remove) unless child_to_remove == JS::Null
      end
    end

    # @rbs current_el: untyped
    # @rbs old_children: Array[VNode | VFragment | String]
    # @rbs new_children: Array[VNode | VFragment | String]
    # @rbs return: void
    def patch_common_children(current_el, old_children, new_children)
      [old_children.length, new_children.length].min.times do |i|
        patch(current_el, old_children[i], new_children[i], i)
      end
    end

    # @rbs current_el: untyped
    # @rbs old_children: Array[VNode | VFragment | String]
    # @rbs new_children: Array[VNode | VFragment | String]
    # @rbs return: void
    def append_missing_children(current_el, old_children, new_children)
      (old_children.length...new_children.length).each do |i|
        current_el.appendChild(create_element(new_children[i]))
      end
    end
  end
end
