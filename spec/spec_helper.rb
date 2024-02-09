# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "baking_rack"
require "debug" unless ENV.key?("GITHUB_ACTION")

BakingRack.config.build_directory = "tmp/specs"

# ensure simplecov isn't missing anything
Zeitwerk::Loader.eager_load_all

Dir[File.join(".", "spec", "support", "**", "*.rb")].sort.each { |f| require f }
