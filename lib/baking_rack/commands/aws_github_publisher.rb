# frozen_string_literal: true

module BakingRack
  module Commands
    class AwsGithubPublisher
      include UsesTerraform

      attr_accessor :filename
      attr_accessor :name

      attr_accessor :bucket_name
      attr_accessor :branch_name
      attr_accessor :directory
      attr_accessor :aws_region
      attr_accessor :verbose

      attr_accessor :role_to_assume
      attr_accessor :role_session_name

      # rubocop:disable Metrics/CyclomaticComplexity

      def initialize(options = {})
        options.each do |key, value|
          send(:"#{key}=", value)
        end

        self.bucket_name ||= default_bucket_name
        self.branch_name ||= default_branch_name
        self.directory ||= default_directory_name
        self.role_to_assume ||= default_role_to_assume

        self.filename ||= default_filename(branch_name)
        self.name ||= default_name(branch_name, directory)
      end

      # rubocop:enable Metrics/CyclomaticComplexity

      # HACK: make this private method public.
      # Unsure why context.send(:binding) doesn't work but context.binding does.

      # rubocop:disable Lint/UselessMethodDefinition
      def binding
        super
      end
      # rubocop:enable Lint/UselessMethodDefinition

      def git_root
        @git_root ||= find_git_root(Dir.pwd)
      end

      def filepath
        git_root.join(".github/workflows", filename)
      end

      def filepath_from_git_root
        filepath.relative_path_from(git_root)
      end

    private

      def default_bucket_name
        read_terraform_output_value("baking_rack_bucket_name") ||
          raise(ArgumentError, "bucket required")
      end

      def default_branch_name
        `git rev-parse --abbrev-ref HEAD`.strip
      end

      def default_filename(branch_name)
        if main_branch?(branch_name)
          "publish.yml"
        else
          "publish-#{branch_name}.yml"
        end
      end

      def default_directory_name
        pwd_relative_to_git_root if Dir.pwd != git_root.to_s
      end

      def default_role_to_assume
        read_terraform_output_value("baking_rack_iam_role_arn") ||
          raise(ArgumentError, "cannot infer role-to-assume, please provide its value")
      end

      def default_name(branch_name, directory_name)
        name = ["Publish"]

        name << " #{directory_name}" if directory_name
        name << " to #{branch_name}" unless main_branch?(branch_name)

        name.join
      end

      def main_branch?(branch_name)
        %w[master main].include?(branch_name)
      end

      def pwd_relative_to_git_root
        Pathname.new(Dir.pwd).relative_path_from(git_root)
      end

      def find_git_root(starting_directory)
        current_directory = Pathname.new(starting_directory).realpath

        until current_directory.root?
          git_dir = current_directory.join(".git")
          return current_directory if git_dir.exist?

          current_directory = current_directory.parent
        end

        raise("Git root not found for: #{starting_directory.inspect}")
      end
    end
  end
end
