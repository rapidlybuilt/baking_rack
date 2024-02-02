# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::Rails::Builder do
  let(:output_directory) { BakingRack.build_directory }
  let(:html_content) { "<p>Hi!</p>" }
  let(:app) { RailsApp }
  let(:builder) { described_class.new(app:, output_directory:) }
  let(:rails_const) { double("Rails", env: rails_env) }
  let(:rails_env) { double("env", production?: true) }

  around :each do |ex|
    # https://github.com/rspec/rspec-core/issues/1598
    RSpec::Mocks.with_temporary_scope do
      with_stub_const(:Rails, rails_const) { ex.run }
    end
  end

  after do
    FileUtils.rm_rf(output_directory)
  end

  it "defaults to copying the public directory" do
    expect(builder.public_directory).to eql("public")
  end

  it "defaults to the first domain in the application's configuration" do
    expect(builder.domain_name).to eql("example.com")
  end

  it "exposes path helpers to the static routes builder" do
    builder = described_class.new(app:) do |b|
      b.define_static_routes do
        get root_path
      end
    end

    expect(builder.static_routes.map(&:path)).to eql(["/"])
  end

  it "precompiles assets during the build" do
    expect(builder).to receive(:system).with({"RAILS_ENV" => "production"}, "bundle exec rake assets:precompile")
    builder.run
  end

  it "clobbers assets during clean" do
    expect(builder).to receive(:system).with({"RAILS_ENV" => "production"}, "bundle exec rake assets:clobber")
    builder.clean
  end

  it "raises an error when run outside of RAILS_ENV=production" do
    expect(rails_env).to receive(:production?).and_return(false)
    expect{builder.run}.to raise_error(BakingRack::Rails::Builder::InvalidRailsEnvironmentError)
  end

  class RailsApp
    module UrlHelpers
      def root_path
        "/"
      end
    end

    class << self
      def call(env)
        ["200", {"Content-Type" => "text/html"}, ["<p>Hi!</p>"]]
      end

      def routes
        OpenStruct.new(url_helpers: UrlHelpers)
      end

      def config
        OpenStruct.new(hosts: ["example.com"])
      end
    end
  end
end
