# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::CLI do
  include ThorSupport

  let(:builder) { BakingRack::Builder.new(app: basic_app, domain_name:) }
  let(:deployer) { BakingRack::Deployer.new }

  before do
    BakingRack.config.builder = builder
    BakingRack.config.deployer = deployer
  end

  describe "build" do
    let(:output) { capture(:stdout) { subject.build } }

    it "runs the builder" do
      expect(output).to include("Built 0 static routes")
    end

    it "raises an error when builder isn't set" do
      BakingRack.config.builder = nil
      expect{output}.to raise_error("You must set BakingRack.config.builder before running!")
    end
  end

  describe "deploy" do
    let(:output) { capture(:stdout) { subject.deploy } }

    it "runs the deployer" do
      expect(output).to include("Uploaded 0 files")
    end

    it "raises an error when deployer isn't set" do
      BakingRack.config.deployer = nil
      expect{output}.to raise_error("You must set BakingRack.config.deployer before running!")
    end
  end

  describe "publish" do
    let(:output) { capture(:stdout) { subject.publish } }

    it "runs the builder and deployer" do
      expect(output).to include("Built 0 static routes")
      expect(output).to include("Uploaded 0 files")
    end
  end

  describe "clean" do
    let(:output) { capture(:stdout) { subject.clean } }

    before do
      subject.options = OpenStruct.new(verbose?: true)
    end

    it "runs clean on the builder" do
      expect(output).to include("Clean started")
    end

    it "raises an error when builder isn't set" do
      BakingRack.config.builder = nil
      expect{output}.to raise_error("You must set BakingRack.config.builder before running!")
    end
  end

  describe "help" do
    let(:output) { capture(:stdout) { subject.help } }

    it "outputs available commands" do
      expect(output).to include("Builds and deploys all static webpages")
    end
  end

  describe "github_publisher" do
    include TerraformSupport

    let(:output) { capture(:stdout) { subject.github_publisher } }
    let(:content) { File.read(".github/workflows/publish.yml") }

    after { FileUtils.rm_rf(".github/workflows/publish.yml") }

    it "writes the file" do
      subject.options = thor_options(role_to_assume: "test-role", bucket: "test")
      expect(output).to include("create  .github/workflows/publish.yml")
      expect(content).to include(%(role-to-assume: "test-role"))
    end

    it "infers the bucket using terraform" do
      stub_terraform_command "output -raw baking_rack_bucket_name", "my-bucket"
      subject.options = thor_options(role_to_assume: "test-role")
      expect(output).to include("create  .github/workflows/publish.yml")
      expect(content).to include("BUCKET_NAME: my-bucket")
    end

    it "errors when the role-to-assume can't be determined" do
      stub_terraform_command "output -raw baking_rack_iam_role_arn", ""

      subject.options = thor_options(bucket: "test")
      expect{output}.to raise_error("cannot infer role-to-assume, please provide its value")
    end

    it "errors when bucket is missing and terraform can't supply it" do
      stub_terraform_command "output -raw baking_rack_bucket_name", ""

      subject.options = thor_options(role_to_assume: "test-role")
      expect{output}.to raise_error(ArgumentError, "bucket required")
    end

    def thor_options(options = {})
      super("github_publisher", options)
    end
  end
end
