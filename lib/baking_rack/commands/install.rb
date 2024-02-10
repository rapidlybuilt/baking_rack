# frozen_string_literal: true

module BakingRack
  module Commands
    module Install
    private

      def run_install
        method = "run_install_#{options.platform.gsub("-", "_")}"
        raise ArgumentError, "unknown platform: #{options.platform.inspect}" unless respond_to?(method, true)

        send(method)
      end

      def run_install_aws_s3_terraform
        install_templates "aws_s3_terraform", "terraform"
      end

      def run_install_terraform_github_publish
        github_publish_workflow_template(
          iam_role: required_terraform_output_value("baking_rack_iam_role_arn"),
        )
      end

      def install_templates(generator, destination = nil)
        directory = init_install_template_root(generator)

        Dir.glob(File.join(directory, "**/*")).each do |path|
          next if File.directory?(path)

          filename = path[directory.length + 1..]
          output = destination ? File.join(destination, filename) : filename
          template filename, output
        end
      end

      def init_install_template_root(name)
        path = File.expand_path(File.join(File.dirname(__FILE__), "../../generators", name))
        BakingRack::CLI.source_root(path)
        path
      end

      def github_publish_workflow_template(iam_role:)
        init_install_template_root "github_publish_workflow"

        context = GithubPublishWorkflow.new(iam_role:).send(:binding)
        template "publish.yml", ".github/workflows/publish.yml", context:
      end

      class GithubPublishWorkflow
        attr_reader :iam_role

        def initialize(iam_role:)
          @iam_role = iam_role
        end
      end
    end
  end
end
