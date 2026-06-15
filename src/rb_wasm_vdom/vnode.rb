# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  # Virtual DOM Node Definition
  class VNode
    attr_reader :tag      #: String
    attr_reader :props    #: Hash[String, String]
    attr_reader :children #: Array[VNode | String]

    # @rbs tag: String
    # @rbs props: Hash[String, String]
    # @rbs children: Array[VNode | String]
    # @rbs return: void
    def initialize(tag, props = {}, children = [])
      @tag = tag
      @props = props
      @children = children
    end
  end
end
