# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::Deployer do
  it "skips unchanged files"

  it "uploads unchanged files when told to force-all"

  describe "ignoring files" do
    it "skips ignored filenames"
  end

  describe "subclass API" do
    it "retrieves content types"

    it "tells whether a path contains a fingerprinted filename"

    it "recognizes file-persisted redirects"
  end
end
