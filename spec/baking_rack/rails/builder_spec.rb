# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::Rails::Builder do
  let(:html_content) { "<p>Hi!</p>" }
  let(:app) { RailsApp.new }
  let(:builder) { described_class.new(app:, build_directory:) }
  let(:rails_const) { double("Rails", env: rails_env) }
  let(:rails_env) { double("env", production?: true, to_s: "production") }

  around :each do |ex|
    # https://github.com/rspec/rspec-core/issues/1598
    RSpec::Mocks.with_temporary_scope do
      with_stub_const(:Rails, rails_const) { ex.run }
    end
  end

  after do
    FileUtils.rm_rf(build_directory)
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
    expect(rails_env).to receive(:to_s).and_return("development")
    expect{builder.run}.to raise_error(BakingRack::Rails::Builder::InvalidRailsEnvironmentError)
  end

  describe "#get_other_rails_routes" do
    let(:builder) do
      described_class.new(app:) do |b|
        b.define_static_routes do
          get_other_rails_routes
        end
      end
    end

    it "adds the other routes to get" do
      get "/", as: :root

      expect(builder.static_routes.map(&:path)).to eql(["/"])
    end

    [404, 403, 500].each do |status|
      it "infers that /#{status}.html probably wants to have a #{status} status code" do
        get "/#{status}.html", as: :not_found

        expect(builder.static_routes.map(&:status)).to eql([status])
      end
    end

    it "recursively drills down into mounted engines" do
      engine = MockEngine.new
      engine.get "/dashboard"
      engine.get "/users"

      mount engine, at: "/admin"

      expect(builder.static_routes.map(&:path)).to contain_exactly("/admin/dashboard", "/admin/users")
    end

    it "handles deeply nested engines" do
      inner_engine = MockEngine.new
      inner_engine.get "/settings"

      outer_engine = MockEngine.new
      outer_engine.get "/overview"
      outer_engine.mount inner_engine, at: "/config"

      mount outer_engine, at: "/admin"

      expect(builder.static_routes.map(&:path)).to contain_exactly(
        "/admin/overview",
        "/admin/config/settings"
      )
    end

    it "combines app routes with engine routes" do
      get "/", as: :root

      engine = MockEngine.new
      engine.get "/about"

      mount engine, at: "/pages"

      expect(builder.static_routes.map(&:path)).to contain_exactly("/", "/pages/about")
    end

  private

    def get(path, as: nil, verb: "GET", parts: [:format])
      app.routes.routes << OpenStruct.new(name: as, path: OpenStruct.new(spec: path), verb:, parts:, app: nil)
    end

    def mount(engine, at:)
      app.routes.routes << OpenStruct.new(
        name: nil,
        path: OpenStruct.new(spec: at),
        verb: "GET",
        parts: [],
        app: engine
      )
    end
  end

  describe "#get_rails_engine_routes" do
    it "adds routes from an engine at the specified path" do
      engine = MockEngine.new
      engine.get "/dashboard"
      engine.get "/settings"

      engine_route = OpenStruct.new(app: engine)

      builder = described_class.new(app:) do |b|
        b.define_static_routes do
          get_rails_engine_routes "/admin", engine_route
        end
      end

      expect(builder.static_routes.map(&:path)).to contain_exactly("/admin/dashboard", "/admin/settings")
    end

    it "supports the except option to skip specific routes" do
      engine = MockEngine.new
      engine.get "/public", as: :public_page
      engine.get "/private", as: :private_page

      engine_route = OpenStruct.new(app: engine)

      builder = described_class.new(app:) do |b|
        b.define_static_routes do
          get_rails_engine_routes "/section", engine_route, except: ["private_page"]
        end
      end

      expect(builder.static_routes.map(&:path)).to eql(["/section/public"])
    end
  end

  module UrlHelpers
    def root_path
      "/"
    end
  end

  class RailsApp
    def call(env)
      ["200", {"Content-Type" => "text/html"}, ["<p>Hi!</p>"]]
    end

    def routes
      @routes ||= OpenStruct.new(url_helpers: UrlHelpers, routes: [])
    end

    def config
      @config ||= OpenStruct.new(hosts: ["example.com"])
    end
  end

  class MockEngine
    def routes
      @routes ||= OpenStruct.new(routes: [])
    end

    def get(path, as: nil, verb: "GET", parts: [:format])
      routes.routes << OpenStruct.new(name: as, path: OpenStruct.new(spec: path), verb:, parts:, app: nil)
    end

    def mount(engine, at:)
      routes.routes << OpenStruct.new(
        name: nil,
        path: OpenStruct.new(spec: at),
        verb: "GET",
        parts: [],
        app: engine
      )
    end
  end
end
