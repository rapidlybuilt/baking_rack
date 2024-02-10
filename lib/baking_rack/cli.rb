# frozen_string_literal: true

require "baking_rack"
require "thor"

require_relative "commands/logger"
require_relative "commands/sub_command_base"
require_relative "commands/install"

module BakingRack
  class CLI < Thor
    include Thor::Actions

    desc "build", "Renders all static webpages and their assets to a build directory"
    method_options verbose: :boolean
    def build
      run_build
    end

    desc "deploy", "Writes the build directory to a remote webserver or CDN"
    method_options dry_run: :boolean
    method_options force_all: :boolean
    method_options verbose: :boolean
    def deploy
      run_deploy
    end

    desc "publish", "Builds and deploys all static webpages"
    method_options dry_run: :boolean
    method_options force_all: :boolean
    method_options verbose: :boolean
    def publish
      run_build
      run_deploy
    end

    desc "clean", "Deletes all build files"
    method_options verbose: :boolean
    def clean
      run_clean
    end

    desc "install PLATFORM", "Creates files for specific use-cases"
    subcommand "install", Commands::Install

  private

    def builder
      BakingRack.config.builder
    end

    def deployer
      BakingRack.config.deployer
    end

    def setup_cli_output
      @setup_cli_output ||= Commands::Logger.new(verbose: options.verbose?).tap do |observer|
        builder&.add_observer(observer)
        deployer&.add_observer(observer)
      end
    end

    def ensure_builder
      setup_cli_output
      builder || raise("You must set BakingRack.config.builder before running!")
    end

    def ensure_deployer
      setup_cli_output
      deployer || raise("You must set BakingRack.config.deployer before running!")
    end

    def run_build
      ensure_builder.run
    end

    def run_deploy
      ensure_deployer.run(
        dry_run: options.dry_run?,
        force_all: options.force_all?,
      )
    end

    def run_clean
      ensure_builder.clean
    end

    class << self
      def exit_on_failure?
        true
      end
    end
  end
end
