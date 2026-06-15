# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  # HTML Template Parser
  class TemplateParser
    # @rbs return: void
    def self.setup_js_parser
      # Add a prefix to the function name to prevent global namespace pollution in JS
      JS.eval(<<~JS)
        window.__RbWasmVdom_parseHTMLToJSON = function(html) {
          const doc = new DOMParser().parseFromString(html, "text/html");
          function walk(node) {
            if (node.nodeType === 3) {
              const text = node.textContent.trim();
              return text ? text : null;
            }
            if (node.nodeType === 1) {
              const obj = { tag: node.tagName.toLowerCase(), props: {}, children: [] };
              for (let i = 0; i < node.attributes.length; i++) {
                obj.props[node.attributes[i].name] = node.attributes[i].value;
              }
              for (let i = 0; i < node.childNodes.length; i++) {
                const childRes = walk(node.childNodes[i]);
                if (childRes !== null) obj.children.push(childRes);
              }
              return obj;
            }
            return null;
          }
          const root = doc.body.firstElementChild;
          return root ? JSON.stringify(walk(root)) : "null";
        }
      JS
      @setup_done = true
    end

    # @rbs html_string: String
    # @rbs return: VNode | String | nil
    def self.parse(html_string)
      setup_js_parser unless @setup_done
      json_str = JS.global.__RbWasmVdom_parseHTMLToJSON(html_string).to_s
      return nil if json_str == "null" || json_str.empty?

      build_ast(JSON.parse(json_str))
    end

    # @rbs data: Hash[String, untyped] | String
    # @rbs return: VNode | String
    def self.build_ast(data)
      return data if data.is_a?(String)

      children = data["children"].map { |child| build_ast(child) }
      VNode.new(data["tag"], data["props"], children)
    end
  end
end
