# frozen_string_literal: true

require "zeitwerk"

lib_directory = File.expand_path(__dir__)

loader = Zeitwerk::Loader.new
loader.push_dir(lib_directory)
loader.ignore(File.join(lib_directory, "baking_rack/version.rb"))
loader.setup # ready!

# Top level module for the gem which exposes a helper method
# for configuring it.
module BakingRack
end
