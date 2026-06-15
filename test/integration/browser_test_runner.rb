require "js"

class BrowserIntegrationTest
  def run_all_tests
    results = { passed: 0, failed: [] }

    begin
      begin
        test_initialize_and_initial_render
        results[:passed] += 1
      rescue StandardError => e
        results[:failed] << "test_initialize_and_initial_render: #{e.message}"
      end

      begin
        test_state_update_re_renders_dom
        results[:passed] += 1
      rescue StandardError => e
        results[:failed] << "test_state_update_re_renders_dom: #{e.message}"
      end

      write_results(results)
    rescue StandardError => e
      write_results({
                      passed: results[:passed],
                      failed: ["run_all_tests: #{e.message}"]
                    })
    end
  end

  def setup_root_element
    document = JS.global[:document]
    root = document.getElementById("root")
    root[:innerHTML] = ""
  end

  def test_initialize_and_initial_render
    setup_root_element
    RbWasmVdom::App.new(
      "#root",
      template: '<div id="test-message">Count: {{ count }}</div>',
      state: { count: 10 },
      methods: {}
    )
    rendered = JS.global[:document].getElementById("test-message")
    raise "Element not found" unless rendered
    raise "Expected 'Count: 10', got '#{rendered[:textContent]}'" unless rendered[:textContent].to_s == "Count: 10"
  end

  def test_state_update_re_renders_dom
    setup_root_element
    app = RbWasmVdom::App.new(
      "#root",
      template: '<span id="counter">{{ count }}</span>',
      state: { count: 0 },
      methods: {}
    )
    reactive_state = app.instance_variable_get(:@state)
    reactive_state[:count] = 5

    counter = JS.global[:document].getElementById("counter")
    raise "Expected '5', got '#{counter[:textContent]}'" unless counter[:textContent].to_s == "5"
  end

  private

  def write_results(results)
    document = JS.global[:document]
    el = document.getElementById("test-results")

    el[:textContent] = serialize_results(results)
    el.setAttribute("data-status", results[:failed].empty? ? "success" : "failure")
  end

  def serialize_results(results)
    failed_json = results[:failed].map { |message| json_escape(message) }.join(",")
    "{\"passed\":#{results[:passed]},\"failed\":[#{failed_json}]}"
  end

  def json_escape(value)
    escaped = ""

    value.to_s.each_char do |char|
      escaped << case char
      when "\\"
        "\\\\"
      when '"'
        "\\\""
      when "\n"
        "\\n"
      when "\r"
        "\\r"
      when "\t"
        "\\t"
      else
        char
                 end
    end

    "\"#{escaped}\""
  end
end
