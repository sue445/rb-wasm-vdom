# frozen_string_literal: true

module TestApp
  def build_test_app(initial_state)
    app = RbWasmVdom::App.allocate

    state = RbWasmVdom::ReactiveState.new(initial_state) {} # rubocop:disable Lint/EmptyBlock

    app.instance_variable_set(:@state, state)
    app.instance_variable_set(:@interpolator, RbWasmVdom::Interpolator.new(state))

    app
  end
end
