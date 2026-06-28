# frozen_string_literal: true
# rbs_inline: enabled

module RbWasmVdom
  module JSConsole
    # Print error to console.error
    # @rbs error: Exception
    def self.print_error(error)
      lines = ["#{error.class}: #{error.message}"]
      backtrace = error.backtrace || []
      lines.concat(backtrace) unless backtrace.empty?
      JS.global[:console].error(lines.join("\n"))
    end
  end
end
