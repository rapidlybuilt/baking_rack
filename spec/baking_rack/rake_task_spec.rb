# frozen_string_literal: true

require "spec_helper"

# This whole thing is HACK-y.

RSpec.describe BakingRack::RakeTask do
  let(:builder) { double("builder", add_observer: nil) }
  let(:deployer) { double("deployer", add_observer: nil) }

  it "defines some rake tasks" do
    rake = described_class.new(builder:, deployer:)

    expect(builder).to receive(:run)
    Rake::Task["baking_rack:build"].invoke

    expect(deployer).to receive(:run)
    Rake::Task["baking_rack:deploy"].invoke

    expect(builder).to receive(:clean)
    Rake::Task["baking_rack:clean"].invoke
  end
end
