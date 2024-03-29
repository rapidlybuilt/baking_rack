# frozen_string_literal: true

module BakingRack
  module Commands
    class Install < SubCommandBase
      include Thor::Actions
      include UsesTerraform

      desc "aws_s3_terraform", "Defines Terraform Resources for deploying to AWS S3 served by CloudFront"
      def aws_s3_terraform
        install_templates "aws_s3_terraform", "terraform", except: %w[cloudfront.tf variables.tf]

        explain_template "aws_s3_terraform", "cloudfront.tf", <<~TEXT

          Add and customize the following origin to your cloudfront distribution:

        TEXT

        explain_template "aws_s3_terraform", "variables.tf", <<~TEXT

          Add and customize the following variables to your terraform install:

        TEXT
      end

      def explain_template(generator, filename, explanation)
        directory = init_install_template_root(generator)
        path = File.join(directory, filename)

        say explanation, :green
        say File.read(path)
      end

      desc "aws_github_publish", "Creates a GitHub Action workflow to continously publish"
      method_option :bucket
      method_option :filename, default: "publish.yml"
      method_option :region, default: "us-east-1"
      method_option :branch, default: "main"
      method_option :role_session_name, default: "GitHub_to_AWS_via_FederatedOIDC"
      method_option :role_to_assign, type: :string, desc: "We attempt to infer this from terraform"
      method_option :verbose, type: :boolean, default: false
      def aws_github_publish
        context = AwsGithubPublish.new.tap do |a|
          a.bucket_name = options.bucket || default_bucket_name
          a.branch_name = options.branch
          a.aws_region = options.region
          a.verbose = options.verbose
          a.role_session_name = "GitHub_to_AWS_via_FederatedOIDC"
          a.role_to_assume = options.role_to_assign ||
                             read_terraform_output_value("baking_rack_iam_role_arn") ||
                             raise(ArgumentError, "cannot infer role-to-assign, please provide its value")
        end

        init_install_template_root "github_publish_workflow"
        template "aws_publish.yml", File.join(".github/workflows/#{options.filename}"), context: context.binding
      end

    private

      def install_templates(generator, destination, except: [])
        directory = init_install_template_root(generator)

        Dir.glob(File.join(directory, "**/*")).each do |path|
          next if File.directory?(path)

          filename = path[directory.length + 1..]
          next if except.include?(filename)

          output = destination ? File.join(destination, filename) : filename
          template filename, output
        end
      end

      def init_install_template_root(name)
        path = File.expand_path(File.join(File.dirname(__FILE__), "../../generators", name))
        self.class.source_root(path)
        path
      end

      def default_bucket_name
        read_terraform_output_value("baking_rack_bucket_name") ||
          raise(ArgumentError, "bucket required")
      end

      class AwsGithubPublish
        attr_accessor :bucket_name
        attr_accessor :branch_name
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
    end
  end
end
