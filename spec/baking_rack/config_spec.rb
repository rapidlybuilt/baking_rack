# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::Config do
  let(:builder) { BakingRack::Builder.new(app: basic_app, domain_name:) }
  let(:instance) { BakingRack::Config.new(build_directory:, builder:) }

  it "delegates define_static_routes to the builder" do
    expect{
      instance.define_static_routes do
        get "/"
      end
    }.to change{instance.builder.static_routes.length}.by(1)
  end
end
