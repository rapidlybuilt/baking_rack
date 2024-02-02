# frozen_string_literal: true

require "fileutils"
require "zeitwerk"

lib_directory = File.expand_path(__dir__)

loader = Zeitwerk::Loader.new
loader.push_dir(lib_directory)
loader.ignore(File.join(lib_directory, "baking_rack/version.rb"))
loader.setup # ready!

module BakingRack
  class Error < StandardError; end
  class UnexpectedStatusCode < Error; end
  class DirectoryMissingError < Error; end

  class << self
    attr_accessor :build_directory

    def redirect_file_content(location)
      %(<html><body>You are being <a href="#{location}">redirected</a>.</body></html>)
    end
  end
end

# Let's use Jekyll's default as our default
BakingRack.build_directory = "_site"
