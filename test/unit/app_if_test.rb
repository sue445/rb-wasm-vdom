# frozen_string_literal: true

require_relative "test_helper"

class AppEachTest < SimpleTestCase
  include TestApp

  def test_build_vdom_renders_if_branch
    app = build_test_app(count: 1)

    ast = RbWasmVdom::VNode.new(
      "div",
      {},
      [
        RbWasmVdom::VNode.new("p", { "#if" => "count > 0" }, ["positive"]),
        RbWasmVdom::VNode.new("p", { "#elsif" => "count < 0" }, ["negative"]),
        RbWasmVdom::VNode.new("p", { "#else" => "" }, ["zero"])
      ]
    )

    vnode = app.send(:build_vdom, ast)

    assert_equal 1, vnode.children.length
    assert_equal ["positive"], vnode.children[0].children
    assert_equal({}, vnode.children[0].props)
  end

  def test_build_vdom_renders_elsif_branch
    app = build_test_app(count: -1)

    ast = RbWasmVdom::VNode.new(
      "div",
      {},
      [
        RbWasmVdom::VNode.new("p", { "#if" => "count > 0" }, ["positive"]),
        RbWasmVdom::VNode.new("p", { "#elsif" => "count < 0" }, ["negative"]),
        RbWasmVdom::VNode.new("p", { "#else" => "" }, ["zero"])
      ]
    )

    vnode = app.send(:build_vdom, ast)

    assert_equal 1, vnode.children.length
    assert_equal ["negative"], vnode.children[0].children
    assert_equal({}, vnode.children[0].props)
  end

  def test_build_vdom_renders_else_branch
    app = build_test_app(count: 0)

    ast = RbWasmVdom::VNode.new(
      "div",
      {},
      [
        RbWasmVdom::VNode.new("p", { "#if" => "count > 0" }, ["positive"]),
        RbWasmVdom::VNode.new("p", { "#elsif" => "count < 0" }, ["negative"]),
        RbWasmVdom::VNode.new("p", { "#else" => "" }, ["zero"])
      ]
    )

    vnode = app.send(:build_vdom, ast)

    assert_equal 1, vnode.children.length
    assert_equal ["zero"], vnode.children[0].children
    assert_equal({}, vnode.children[0].props)
  end

  def test_build_vdom_renders_no_conditional_branch_when_if_is_false_without_else
    app = build_test_app(visible: false)

    ast = RbWasmVdom::VNode.new(
      "div",
      {},
      [
        RbWasmVdom::VNode.new("p", { "#if" => "visible" }, ["shown"])
      ]
    )

    vnode = app.send(:build_vdom, ast)

    assert_equal 0, vnode.children.length
  end

  def test_build_vdom_combines_if_and_each
    app = build_test_app(visible: true, items: %w[Ruby Wasm])

    ast = RbWasmVdom::VNode.new(
      "ul",
      {},
      [
        RbWasmVdom::VNode.new("li", { "#if" => "visible", "#each" => "item in items" }, ["{{ item }}"])
      ]
    )

    vnode = app.send(:build_vdom, ast)

    assert_equal 2, vnode.children.length
    assert_equal ["Ruby"], vnode.children[0].children
    assert_equal ["Wasm"], vnode.children[1].children
  end
end
