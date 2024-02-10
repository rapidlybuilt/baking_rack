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
      expect(output).to include("install PLATFORM")
    end
  end
end
