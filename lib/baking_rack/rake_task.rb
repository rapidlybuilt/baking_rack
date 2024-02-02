# frozen_string_literal: true

require "baking_rack"
require "rake"
require "rake/tasklib"
require "optparse"

module BakingRack
  # Provides a custom rake tasks.
  #
  # require 'baking_rack/rake_task'
  # RakingRack::RakeTask.new
  class RakeTask < ::Rake::TaskLib
    def initialize(builder:, deployer:, namespace: :baking_rack, **_kargs)
      super()
      @namespace = namespace
      @cli_output = CommandLineOutput.new(verbose: ENV.key?("VERBOSE"))

      builder.add_observer(@cli_output)
      deployer.add_observer(@cli_output)

      desc "Renders all static webpages and their assets to a build directory"
      task task_name("build") => app_requirement_tasks do
        builder.run
      end

      desc "Writes the build directory to a remote webserver or CDN"
      task task_name("deploy") => app_requirement_tasks do
        deployer.run
      end

      desc "Builds and deploys all static webpages"
      task task_name("publish") => [task_name("build"), task_name("deploy")]

      desc "Deletes all build files"
      task task_name("clean") => app_requirement_tasks do
        builder.clean
      end
    end

  private

    def task_name(name)
      "#{@namespace}:#{name}"
    end

    def app_requirement_tasks
      defined?(::Rails) ? [:environment] : []
    end
  end
end
