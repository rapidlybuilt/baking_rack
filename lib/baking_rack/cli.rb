# frozen_string_literal: true

require "baking_rack"
require "thor"

require_relative "commands/aws_github_publisher"
require_relative "commands/logger"

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

    desc "github_publisher", "Generate a GitHub Action to publish automatically on commit to a branch."
    method_option :bucket
    method_option :name, type: :string
    method_option :filename, type: :string
    method_option :region, default: "us-east-1"
    method_option :branch, type: :string
    method_option :role_session_name, default: "GitHub_to_AWS_via_FederatedOIDC"
    method_option :role_to_assume, type: :string, desc: "We attempt to infer this from terraform"
    method_option :directory, type: :string
    method_option :verbose, type: :boolean, default: false
    def github_publisher
      context = Commands::AwsGithubPublisher.new(
        filename: options.filename,

        name: options.name,
        directory: options.directory,
        branch_name: options.branch_name,
        bucket_name: options.bucket,
        aws_region: options.region,
        verbose: options.verbose,

        role_session_name: options.role_session_name,
        role_to_assume: options.role_to_assume,
      )

      init_install_template_root "github_publisher"
      template "aws_publish.yml", context.filepath, context: context.binding
    end

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

    def init_install_template_root(name)
      path = File.expand_path(File.join(File.dirname(__FILE__), "../generators", name))
      self.class.source_root(path)
      path
    end

    class << self
      def exit_on_failure?
        true
      end
    end
  end
end
