# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::Builder do
  let(:build_directory) { BakingRack.build_directory }
  let(:domain_name) { "example.com" }
  let(:html_content) { "<p>Hi!</p>" }
  let(:builder) { described_class.new(app: basic_app, build_directory:, domain_name:) }

  let(:io) { double("io", puts: nil) }
  let(:observer) { BakingRack::CommandLineOutput.new(io:, verbose: true) }

  let(:basic_app) do
    # Rack app that returns HTML contenet for all URLs
    Proc.new do |env|
      ["200", {"Content-Type" => "text/html"}, [html_content]]
    end
  end

  after do
    FileUtils.rm_rf(build_directory)
  end

  describe "build" do
    it "retrieves a route from the app and writes it to the file" do
      described_class.run(app: basic_app, build_directory:, domain_name:) do |b|
        b.define_static_routes do
          get "/foo.html"
        end
      end

      expect(read_build_file("foo.html")).to eql(html_content)
    end

    it "writes redirects with custom file content" do
      app = Proc.new do |env|
        ["301", {"Location" => "/bar.html"}, []]
      end

      builder = described_class.new(app:, build_directory:, domain_name:) do |b|
        b.define_static_routes do
          get "/foo.html", status: 301
        end
      end

      builder.run

      expect(read_build_file("foo.html")).to eql(BakingRack.redirect_file_content("/bar.html"))
    end

    it "raises an error when the returned status differs from the expected one" do
      builder = described_class.new(app: basic_app, build_directory:, domain_name:) do |b|
        b.define_static_routes do
          get "/foo.html", status: 301
        end
      end

      expect{builder.run}.to raise_error(BakingRack::UnexpectedStatusCode)
    end

    it "appends index.html to naked directories when writing to the file" do
      builder = described_class.new(app: basic_app, build_directory:, domain_name:) do |b|
        b.define_static_routes do
          get "/"
        end
      end

      builder.run

      expect(read_build_file("index.html")).to eql(html_content)
    end

    it "lazily runs #define_static_routes" do
      expect do
        described_class.new(app: basic_app, build_directory:, domain_name:) do |b|
          b.define_static_routes do
            raise "asdf"
          end
        end
      end.not_to raise_error
    end

    it "copies all files in the directory into base of the output directory" do
      other_directory = "tmp/src"

      FileUtils.mkdir_p(File.join(other_directory, "assets"))
      File.write(File.join(other_directory, "favicon.ico"), "BINARY")
      File.write(File.join(other_directory, "assets/application.js"), "alert('hi');")

      app = Proc.new do |env|
        ["200", {"Content-Type" => "text/html"}, [html_content]]
      end

      builder = described_class.new(app:, build_directory:, domain_name:)
      builder.public_directory = other_directory

      builder.run

      expect(read_build_file("favicon.ico")).to eql("BINARY")
      expect(read_build_file("assets/application.js")).to eql("alert('hi');")
    ensure
      FileUtils.rm_rf(other_directory) rescue nil
    end

    it "protects against writing files outside the output directory" do
      expect{builder.send(:write_file, "../Rakefile", "foo") }.to raise_error(ArgumentError)
    end

    it "notifies observers about specific routes" do
      builder = described_class.new(app: basic_app, build_directory:, domain_name:) do |b|
        b.define_static_routes do
          get "/"
        end
      end

      expect(io).to receive(:puts).with("#{colorize :green, "200"} /")

      builder.add_observer(observer)
      builder.run
    end
  end

  describe "clean" do
    it "removes the output directory" do
      FileUtils.mkdir_p(build_directory)

      builder = described_class.new(app: basic_app, build_directory:, domain_name:)
      builder.clean

      expect(File.directory?(build_directory)).to eql(false)
    end

    it "notifies observers when the clean is started and finished" do
      builder.add_observer(observer)
      expect(io).to receive(:puts).with("#{colorize :yellow, "Clean started"} #{builder.inspect}")
      expect(io).to receive(:puts).with(colorize :yellow, "Clean finished")
      builder.clean
    end
  end

  private

  def read_build_file(filename)
    File.read(File.join(build_directory, filename))
  end
end
