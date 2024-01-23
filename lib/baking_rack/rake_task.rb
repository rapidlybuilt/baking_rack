# frozen_string_literal: true

require "rake"
require "rake/tasklib"

module BakingRack
  # Provides a custom rake tasks.
  #
  # require 'baking_rack/rake_task'
  # RakingRack::RakeTask.new
  class RakeTask < ::Rake::TaskLib

    def initialize(namespace = :baking_rack, *args, &task_block)
      super()
      @namespace = namespace

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

    def builder
      BakingRack::BUILDER
    rescue NameError
      raise InvalidRakeSetup, "You must defined BakingRack::BUILDER before running this task"
    end

    def deployer
      BakingRack::DEPLOYER
    rescue NameError
      raise InvalidRakeSetup, "You must defined BakingRack::DEPLOYER before running this task"
    end
  end
end
