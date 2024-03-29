# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::Commands::Install do
  include ThorSupport
  include TerraformSupport

  let(:builder) { BakingRack::Builder.new(app: basic_app, domain_name:) }
  let(:deployer) { BakingRack::Deployer.new }

  before do
    BakingRack.config.builder = builder
    BakingRack.config.deployer = deployer
  end

  describe "aws_s3_terraform" do
    let(:output) { capture(:stdout) { subject.aws_s3_terraform } }

    after { FileUtils.rm_rf("terraform") }

    it "writes template files" do
      expect(output).to include("create  terraform/baking_rack.tf")
    end
  end

  describe "aws_github_publish" do
    let(:output) { capture(:stdout) { subject.aws_github_publish } }
    let(:content) { File.read(".github/workflows/publish.yml") }

    after { FileUtils.rm_rf(".github/workflows/publish.yml") }

    it "writes the file" do
      subject.options = thor_options(role_to_assign: "test-role", bucket: "test")
      expect(output).to include("create  .github/workflows/publish.yml")
      expect(content).to include(%(role-to-assume: "test-role"))
    end

    it "infers the bucket using terraform" do
      stub_terraform_command "output -raw baking_rack_bucket_name", "my-bucket"
      subject.options = thor_options(role_to_assign: "test-role")
      expect(output).to include("create  .github/workflows/publish.yml")
      expect(content).to include("BUCKET_NAME: my-bucket")
    end

    it "errors when the role-to-assign can't be determined" do
      subject.options = thor_options(bucket: "test")
      expect{output}.to raise_error("cannot infer role-to-assign, please provide its value")
    end

    it "errors when bucket is missing and terraform can't supply it" do
      subject.options = thor_options(role_to_assign: "test-role")
      expect{output}.to raise_error(ArgumentError, "bucket required")
    end

    def thor_options(options = {})
      super("aws_github_publish", options)
    end
  end

  describe "help" do
    let(:output) { capture(:stdout) { subject.help } }

    it "outputs available commands" do
      expect(output).to include("install aws_github_publish")
    end
  end
end
