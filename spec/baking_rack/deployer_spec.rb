# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::Deployer do
  let(:deployer) { described_class.new }

  it "uploads multiple files" do
    write_file "favicon.ico", "BINARY"
    write_file "assets/application.js", "alert('hi');"

    expect(deployer).to receive(:upload_file).with(deploy_file("favicon.ico"))
    expect(deployer).to receive(:upload_file).with(deploy_file("assets/application.js"))

    deployer.run
 end

  it "skips unchanged files" do
    write_file "favicon.ico", "BINARY"

    expect(deployer).to receive(:unchanged?).with(deploy_file("favicon.ico")).and_return(true)
    expect(deployer).not_to receive(:upload_file).with(deploy_file("favicon.ico"))

    deployer.run
  end

  it "uploads unchanged files when told to force-all" do
    deployer = described_class.new
    expect(deployer).not_to receive(:unchanged?)

    deployer.run(force_all: true)
  end

  it "raises an error when the source directory is missing" do
    FileUtils.rm_rf(build_directory)
    expect{deployer.run}.to raise_error(BakingRack::DirectoryMissingError)
  end

  describe "ignoring files" do
    it "skips ignored filenames" do
      write_file "favicon.ico", "BINARY"
      deployer = described_class.new(ignored_filenames: %w[favicon.ico])
      expect(deployer).not_to receive(:unchanged?)
      expect(deployer).not_to receive(:upload_file)

      deployer.run
    end
  end

  describe "subclass API" do
    it "retrieves content types" do
      expect(deployer.send(:content_type_for, "foo/bar.jpg")).to eql("image/jpeg")
    end

    it "retrieves content types with charset" do
      expect(deployer.send(:content_type_with_charset_for, "foo/bar.html")).to eql("text/html; charset=utf-8")
    end

    it "tells whether a path contains a fingerprinted filename" do
      expect(deployer.send(:fingerprinted?, "foo/bar-00bfe90b789ca3d522ceb4d3dc728007.jpg")).to eql(true)
      expect(deployer.send(:fingerprinted?, "foo/bar.jpg")).to eql(false)
    end

    it "recognizes file-persisted redirects" do
      write_file "favicon.ico", BakingRack.redirect_file_content("foo.html")

      file = deploy_file("favicon.ico")

      expect(file.redirect?).to eql(true)
      expect(file.redirect_location).to eql("foo.html")
    end

    it "recogizes when a file isn't a redirect" do
      write_file "favicon.ico", "BINARY"

      file = deploy_file("favicon.ico")

      expect(file.redirect?).to eql(false)
      expect(file.redirect_location).to eql(nil)
    end
  end

  describe "CLI Output" do
    let(:io) { double("io", puts: nil) }
    let(:observer) { BakingRack::Commands::Logger.new(io:, verbose: true) }

    it "outputs uploaded filenames" do
      write_file "favicon.ico", "BINARY"

      expect(io).to receive(:puts).with("#{colorize :green, "Uploaded"} favicon.ico")

      deployer.add_observer(observer)
      deployer.run
    end

    it "outputs skipped filenames" do
      write_file "favicon.ico", "BINARY"

      expect(deployer).to receive(:unchanged?).with(deploy_file("favicon.ico")).and_return(true)
      expect(io).to receive(:puts).with("#{colorize :yellow, "Skipped "} favicon.ico")

      deployer.add_observer(observer)
      deployer.run
    end
  end

  private

  def deploy_file(path)
    BakingRack::Deployer::DeployFile.new(build_directory, path)
  end

  def write_file(path, content)
    FileUtils.mkdir_p(File.join(build_directory, File.dirname(path)))
    File.write(File.join(build_directory, path), content)
  end
end
