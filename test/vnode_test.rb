require "minitest/autorun"
require_relative "../src/rb_wasm_vdom/vnode"

class TestVNode < Minitest::Test
  # Test the initialization of a simple VNode without children or props
  def test_initialize_basic
    vnode = RbWasmVdom::VNode.new("div")

    assert_equal "div", vnode.tag
    assert_equal({}, vnode.props)
    assert_equal [], vnode.children
  end

  # Test the initialization of a VNode with properties and children
  def test_initialize_with_props_and_children
    props = { "class" => "container", "id" => "app" }
    children = ["Hello, World!"]

    vnode = RbWasmVdom::VNode.new("div", props, children)

    assert_equal "div", vnode.tag
    assert_equal props, vnode.props
    assert_equal children, vnode.children
  end
end
