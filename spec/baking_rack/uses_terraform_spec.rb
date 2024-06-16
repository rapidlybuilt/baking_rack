# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::UsesTerraform do
  include TerraformSupport

  class self::TestModule < BakingRack::Deployer
    include BakingRack::UsesTerraform
  end

  let(:instance) { self.class::TestModule.new }

  it "reads terraform output values" do
    stub_terraform_command "output -raw domain_name", "example.com"

    expect(
      instance.send(:read_terraform_output_value, "domain_name")
    ).to eql("example.com")
  end

  it "returns nil if terraform doesn't have that output name" do
    stub_terraform_command "output -raw domain_name", "No outputs found"

    expect(
      instance.send(:read_terraform_output_value, "domain_name")
    ).to eql(nil)
  end

  it "raises an error when the command only outputs to stderr" do
    stub_terraform_command "output -raw domain_name", "", "Invalid input"
    expect(instance).to receive(:warn).with("Invalid input")

    expect{
      instance.send(:read_terraform_output_value, "domain_name")
    }.to raise_error(BakingRack::UsesTerraform::Error)
  end
end
