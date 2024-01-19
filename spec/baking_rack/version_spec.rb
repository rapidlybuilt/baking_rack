# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::VERSION, type: :property do
  it "exposes the version" do
    expect(BakingRack::VERSION).to be_kind_of(String)
  end
end
