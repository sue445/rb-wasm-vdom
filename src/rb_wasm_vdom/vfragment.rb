# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  # Virtual DOM Fragment Definition
  class VFragment
    attr_reader :children #: Array[VNode | VFragment | String]

    # @rbs children: Array[VNode | VFragment | String]
    # @rbs return: void
    def initialize(children = [])
      @children = children
    end
  end
end
