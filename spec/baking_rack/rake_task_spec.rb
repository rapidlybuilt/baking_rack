# frozen_string_literal: true

require "spec_helper"

# This whole thing is HACK-y.

RSpec.describe BakingRack::RakeTask do
  let(:builder) { double("builder") }
  let(:deployer) { double("deployer") }

  before do
    begin
      Rake::Task["baking_rack:build"]
    rescue
      described_class.new
    end
  end

  describe "with proper set up" do
    before do
      BakingRack.const_set(:BUILDER, builder)
      BakingRack.const_set(:DEPLOYER, deployer)
    end

    after do
      BakingRack.instance_eval { remove_const("BUILDER") }
      BakingRack.instance_eval { remove_const("DEPLOYER") }
    end

    it "uses the BakingRack::BUILDER constant when building" do
      expect(builder).to receive(:run)
      Rake::Task["baking_rack:build"].invoke
    end

    it "uses the BakingRack::BUILDER constant when deploying" do
      expect(deployer).to receive(:run)
      Rake::Task["baking_rack:deploy"].invoke
    end

    it "uses both BUILDER when cleaning" do
      expect(builder).to receive(:clean)
      Rake::Task["baking_rack:clean"].invoke
    end
  end

  xit "raises an error when building without a BUILDER" do
    expect{
      Rake::Task["baking_rack:build"].invoke
    }.to raise_error(BakingRack::InvalidRakeSetup)
  end

  xit "raises an error when deploying without a DEPLOYER" do
    expect{
      Rake::Task["baking_rack:deploy"].invoke
    }.to raise_error(BakingRack::InvalidRakeSetup)
  end
end
