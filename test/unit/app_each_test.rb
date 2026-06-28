# frozen_string_literal: true

require_relative "test_helper"

class AppEachTest < SimpleTestCase
  include TestApp
  include JsStubHelper

  def test_build_vdom_expands_array_with_each
    app = build_test_app(items: %w[Ruby Wasm VDOM])

    ast = RbWasmVdom::VNode.new(
      "ul",
      {},
      [
        RbWasmVdom::VNode.new("li", { "#each" => "item in items" }, ["{{ item }}"])
      ]
    )

    vnode = app.send(:build_vdom, ast)

    assert_equal "ul", vnode.tag
    assert_equal 3, vnode.children.length

    assert_equal "li", vnode.children[0].tag
    assert_equal({}, vnode.children[0].props)
    assert_equal ["Ruby"], vnode.children[0].children

    assert_equal "li", vnode.children[1].tag
    assert_equal({}, vnode.children[1].props)
    assert_equal ["Wasm"], vnode.children[1].children

    assert_equal "li", vnode.children[2].tag
    assert_equal({}, vnode.children[2].props)
    assert_equal ["VDOM"], vnode.children[2].children
  end

  def test_build_vdom_expands_array_with_index
    app = build_test_app(items: %w[Ruby Wasm])

    ast = RbWasmVdom::VNode.new(
      "ol",
      {},
      [
        RbWasmVdom::VNode.new("li", { "#each" => "item, index in items" }, ["{{ index }}: {{ item }}"])
      ]
    )

    vnode = app.send(:build_vdom, ast)

    assert_equal "ol", vnode.tag
    assert_equal 2, vnode.children.length
    assert_equal ["0: Ruby"], vnode.children[0].children
    assert_equal ["1: Wasm"], vnode.children[1].children
  end

  def test_build_vdom_expands_hash_with_key_and_value
    app = build_test_app(scores: { alice: 90, bob: 75 })

    ast = RbWasmVdom::VNode.new(
      "ul",
      {},
      [
        RbWasmVdom::VNode.new("li", { "#each" => "name, score in scores" }, ["{{ name }}: {{ score }}"])
      ]
    )

    vnode = app.send(:build_vdom, ast)

    assert_equal "ul", vnode.tag
    assert_equal 2, vnode.children.length

    assert_equal "li", vnode.children[0].tag
    assert_equal({}, vnode.children[0].props)
    assert_equal ["alice: 90"], vnode.children[0].children

    assert_equal "li", vnode.children[1].tag
    assert_equal({}, vnode.children[1].props)
    assert_equal ["bob: 75"], vnode.children[1].children
  end

  def test_build_vdom_interpolates_each_locals_in_props
    app = build_test_app(items: %w[ruby wasm])

    ast = RbWasmVdom::VNode.new(
      "ul",
      {},
      [
        RbWasmVdom::VNode.new(
          "li",
          {
            "#each" => "item in items",
            "class" => "item-{{ item }}",
            "data-name" => "{{ item }}"
          },
          ["{{ item }}"]
        )
      ]
    )

    vnode = app.send(:build_vdom, ast)

    first_item = vnode.children[0]
    second_item = vnode.children[1]

    assert_equal({ "class" => "item-ruby", "data-name" => "ruby" }, first_item.props)
    assert_equal ["ruby"], first_item.children

    assert_equal({ "class" => "item-wasm", "data-name" => "wasm" }, second_item.props)
    assert_equal ["wasm"], second_item.children
  end

  def test_build_vdom_removes_each_directive_from_rendered_props
    app = build_test_app(items: ["Ruby"])

    ast = RbWasmVdom::VNode.new(
      "ul",
      {},
      [
        RbWasmVdom::VNode.new(
          "li",
          {
            "#each" => "item in items",
            "class" => "item"
          },
          ["{{ item }}"]
        )
      ]
    )

    vnode = app.send(:build_vdom, ast)
    item = vnode.children[0]

    assert_equal({ "class" => "item" }, item.props)
    assert_equal nil, item.props["#each"]
  end

  def test_build_vdom_renders_no_nodes_for_non_collection_each_target
    app = build_test_app(items: "not collection")

    ast = RbWasmVdom::VNode.new(
      "ul",
      {},
      [
        RbWasmVdom::VNode.new("li", { "#each" => "item in items" }, ["{{ item }}"])
      ]
    )

    vnode = app.send(:build_vdom, ast)

    assert_equal "ul", vnode.tag
    assert_equal 0, vnode.children.length
  end

  def test_build_vdom_expands_js_object_with_each
    app = build_test_app(items: js_array('["Ruby", "Wasm", "VDOM"]'))

    ast = RbWasmVdom::VNode.new(
      "ul",
      {},
      [
        RbWasmVdom::VNode.new("li", { "#each" => "item in items" }, ["{{ item }}"])
      ]
    )

    vnode = app.send(:build_vdom, ast)

    assert_equal "ul", vnode.tag
    assert_equal 3, vnode.children.length

    assert_equal "li", vnode.children[0].tag
    assert_equal({}, vnode.children[0].props)
    assert_equal ["Ruby"], vnode.children[0].children

    assert_equal "li", vnode.children[1].tag
    assert_equal({}, vnode.children[1].props)
    assert_equal ["Wasm"], vnode.children[1].children

    assert_equal "li", vnode.children[2].tag
    assert_equal({}, vnode.children[2].props)
    assert_equal ["VDOM"], vnode.children[2].children
  end

  def test_build_vdom_expands_js_object_with_index
    app = build_test_app(items: js_array('["Ruby", "Wasm"]'))

    ast = RbWasmVdom::VNode.new(
      "ol",
      {},
      [
        RbWasmVdom::VNode.new("li", { "#each" => "item, index in items" }, ["{{ index }}: {{ item }}"])
      ]
    )

    vnode = app.send(:build_vdom, ast)

    assert_equal "ol", vnode.tag
    assert_equal 2, vnode.children.length
    assert_equal ["0: Ruby"], vnode.children[0].children
    assert_equal ["1: Wasm"], vnode.children[1].children
  end
end
