# frozen_string_literal: true

require "baking_rack"
require "thor"

require_relative "commands/logger"

module BakingRack
  class CLI < Thor
    include Thor::Actions
    include UsesTerraform

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
    method_option :role_to_assign, type: :string, desc: "We attempt to infer this from terraform"
    method_option :directory, type: :string
    method_option :verbose, type: :boolean, default: false
    def github_publisher
      context = AwsGithubPublish.new.tap do |a|
        a.bucket_name = options.bucket || default_bucket_name
        a.branch_name = options.branch || default_branch_name
        a.aws_region = options.region
        a.verbose = options.verbose
        a.directory = options.directory || (pwd_relative_to_git_root if Dir.pwd != git_root.to_s)

        a.name = options.name || default_name(a.branch_name, a.directory)

        a.role_session_name = "GitHub_to_AWS_via_FederatedOIDC"
        a.role_to_assume = options.role_to_assign ||
                           read_terraform_output_value("baking_rack_iam_role_arn") ||
                           raise(ArgumentError, "cannot infer role-to-assign, please provide its value")
      end

      filename = options.filename || default_filename(context.branch_name)

      init_install_template_root "github_publisher"
      template "aws_publish.yml", git_root.join(".github/workflows", filename), context: context.binding
    end

  private

    def builder
      BakingRack.config.builder
    end

    def deployer
      BakingRack.config.deployer
    end

    def pwd_relative_to_git_root
      Pathname.new(Dir.pwd).relative_path_from(git_root)
    end

    def git_root
      @git_root ||= find_git_root(Dir.pwd)
    end

    def find_git_root(starting_directory)
      current_directory = Pathname.new(starting_directory).realpath

      until current_directory.root?
        git_dir = current_directory.join('.git')
        return current_directory if git_dir.exist?
        current_directory = current_directory.parent
      end

      raise("Git root not found for: #{starting_directory.inspect}")
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

    def default_filename(branch_name)
      if main_branch?(branch_name)
        "publish.yml"
      else
        "publish-#{branch_name}.yml"
      end
    end

    def main_branch?(branch_name)
      %w[master main].include?(branch_name)
    end

    def default_name(branch_name, directory_name)
      name = ["Publish"]

      name << " #{directory_name}" if directory_name
      name << " to #{branch_name}" unless main_branch?(branch_name)

      name.join("")
    end

    def default_branch_name
      `git rev-parse --abbrev-ref HEAD`.strip
    end

    def default_bucket_name
      read_terraform_output_value("baking_rack_bucket_name") ||
        raise(ArgumentError, "bucket required")
    end

    class AwsGithubPublish
      attr_accessor :name
      attr_accessor :bucket_name
      attr_accessor :branch_name
      attr_accessor :directory
      attr_accessor :aws_region
      attr_accessor :role_to_assume
      attr_accessor :role_session_name
      attr_accessor :verbose

      # HACK: make this private method public.
      # Unsure why context.send(:binding) doesn't work but context.binding does.

      # rubocop:disable Lint/UselessMethodDefinition
      def binding
        super
      end
      # rubocop:enable Lint/UselessMethodDefinition
    end

    class << self
      def exit_on_failure?
        true
      end
    end
  end
end
