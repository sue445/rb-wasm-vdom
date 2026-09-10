# frozen_string_literal: true

def build_rb_wasm_vdom(dst_filename:, minify:)
  with_disabled_require do
    with_suppressed_reinitialized_constant_warnings do
      Rbpacker::Cli.new.perform(
        src_file: File.join(root_dir, "src", "rb_wasm_vdom.rb"),
        dst_file: File.join(root_dir, "dist", dst_filename),
        minify: minify,
      )
    end
  end
end

def with_disabled_require
  kernel = Kernel
  original_require = kernel.instance_method(:require)

  kernel.define_method(:require) do |_path|
    false
  end

  yield
ensure
  kernel.define_method(:require, original_require) if original_require
end

def with_suppressed_reinitialized_constant_warnings # rubocop:disable Metrics/MethodLength
  original_warn = Warning.method(:warn)

  Warning.define_singleton_method(:warn) do |message, category: nil, **kwargs|
    if message.include?("warning: already initialized constant") ||
       message.include?("warning: previous definition of")
      nil
    else
      original_warn.call(message, category: category, **kwargs)
    end
  end

  yield
ensure
  Warning.define_singleton_method(:warn, original_warn) if original_warn
end

require "rake/clean"

CLOBBER.include("dist")

SRC_FILES = FileList["src/**/*.rb"]

directory "dist"

file "dist/rb-wasm-vdom.rb" => ["dist", *SRC_FILES] do
  build_rb_wasm_vdom(dst_filename: "rb-wasm-vdom.rb", minify: false)
end

file "dist/rb-wasm-vdom.min.rb" => ["dist", *SRC_FILES] do
  build_rb_wasm_vdom(dst_filename: "rb-wasm-vdom.min.rb", minify: true)
end

desc "Build dist/*.rb"
task build: %w[dist/rb-wasm-vdom.rb dist/rb-wasm-vdom.min.rb]
