# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::Commands::Install do
  include ThorSupport

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
      subject.options = OpenStruct.new("role_to_assign" => "test-role")
      expect(output).to include("create  .github/workflows/publish.yml")
      expect(content).to include(%(role-to-assume: "test-role"))
    end

    it "errors when the role-to-assign can't be determined" do
      expect{output}.to raise_error("cannot infer role-to-assign, please provide its value")
    end
  end

  describe "help" do
    let(:output) { capture(:stdout) { subject.help } }

    it "outputs available commands" do
      expect(output).to include("install aws_github_publish")
    end
  end
end
