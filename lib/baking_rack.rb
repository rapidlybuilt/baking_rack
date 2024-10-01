# frozen_string_literal: true

require "fileutils"
require "zeitwerk"

lib_directory = File.expand_path(__dir__)

loader = Zeitwerk::Loader.new
loader.push_dir(lib_directory)
loader.ignore(File.join(lib_directory, "baking_rack/cli.rb"))
loader.ignore(File.join(lib_directory, "baking_rack/mime_types.rb"))
loader.ignore(File.join(lib_directory, "baking_rack/version.rb"))
loader.ignore(File.join(lib_directory, "baking_rack/commands/*"))
loader.setup # ready!

module BakingRack
  class Error < StandardError; end
  class UnexpectedStatusCode < Error; end
  class DirectoryMissingError < Error; end

  class << self
    def config
      @config ||= Config.new(
        build_directory: "_site",          # Jekyll's default
        ignored_filenames: %w[.DS_Store],  # macOS pollution
      )
      yield @config if block_given?
      @config
    end

    def redirect_file_content(location)
      %(<html><body>You are being <a href="#{location}">redirected</a>.</body></html>)
    end
  end
end
