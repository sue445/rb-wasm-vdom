module RbWasmVdom
  # Virtual DOM Node Definition
  class VNode
    attr_reader :tag, :props, :children

    def initialize(tag, props = {}, children = [])
      @tag = tag
      @props = props
      @children = children
    end
  end
end
