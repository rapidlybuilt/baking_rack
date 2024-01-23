# frozen_string_literal: true

require "fileutils"
require "zeitwerk"

lib_directory = File.expand_path(__dir__)

loader = Zeitwerk::Loader.new
loader.push_dir(lib_directory)
loader.ignore(File.join(lib_directory, "baking_rack/railtie.rb"))
loader.ignore(File.join(lib_directory, "baking_rack/version.rb"))
loader.setup # ready!

module BakingRack
  class Error < StandardError ; end
  class UnexpectedStatusCode < Error ; end
  class InvalidRakeSetup < Error ; end

  class << self
    def redirect_file_content(location)
      %(<html><body>You are being <a href="#{location}">redirected</a>.</body></html>)
    end
  end
end

require "baking_rack/railtie" if defined?(Rails::Railtie)
