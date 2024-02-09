# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::AwsS3::Deployer do
  let(:s3) { double(:s3, bucket: s3_bucket) }
  let(:s3_bucket) { double(:s3_bucket) }
  let(:bucket_name) { "my-bucket" }

  before do
    allow(Aws::S3::Resource).to receive(:new).and_return(s3)
  end

  it "writes new files to S3" do
    write_file "favicon.png", "BINARY"

    expect(s3_bucket).to receive(:objects).and_return([])
    expect_s3_put(
      path: "favicon.png",
      acl: "public-read",
      body: "BINARY",
      cache_control: "public,max-age=10",
      content_type: "image/png"
    )

    deployer.run
  end

  it "writes modifies files to S3" do
    write_file "favicon.png", "BINARY"

    expect(s3_bucket).to receive(:objects).and_return([
      double(key: "favicon.png", etag: Digest::MD5.hexdigest("CHANGED").inspect),
    ])

    expect_s3_put(
      path: "favicon.png",
      acl: "public-read",
      body: "BINARY",
      cache_control: "public,max-age=10",
      content_type: "image/png"
    )

    deployer.run
  end

  it "doesn't write unmodified files to S3" do
    write_file "favicon.png", "BINARY"

    expect(s3_bucket).to receive(:objects).and_return([
      double(key: "favicon.png", etag: Digest::MD5.hexdigest("BINARY").inspect),
    ])

    expect_no_s3_put

    deployer.run
  end

  it "places a long cache time on fingerprinted files" do
    write_file "favicon-00bfe90b789ca3d522ceb4d3dc728007.png", "BINARY"

    expect(s3_bucket).to receive(:objects).and_return([
      double(key: "favicon-00bfe90b789ca3d522ceb4d3dc728007.png", etag: Digest::MD5.hexdigest("CHANGED").inspect),
    ])

    expect_s3_put(
      path: "favicon-00bfe90b789ca3d522ceb4d3dc728007.png",
      acl: "public-read",
      body: "BINARY",
      cache_control: "public,max-age=31556926",
      content_type: "image/png"
    )

    deployer.run
  end

  it "places a redirect location on redirects" do
    write_file "favicon.png", BakingRack.redirect_file_content("foo.html")

    expect(s3_bucket).to receive(:objects).and_return([])

    expect_s3_put(
      path: "favicon.png",
      acl: "public-read",
      body: BakingRack.redirect_file_content("foo.html"),
      cache_control: "public,max-age=10",
      content_type: "image/png",
      website_redirect_location: "foo.html",
    )

    deployer.run
  end

  it "doesn't write files during a dry run" do
    write_file "favicon.png", "BINARY"

    expect(s3_bucket).to receive(:objects).and_return([])
    expect_no_s3_put

    deployer.run(dry_run: true)
  end

  describe "bucket_name argument" do
    include TerraformSupport

    it "reads the bucket name from the terraform variable file by default" do
      stub_terraform_command "output -raw baking_rack_bucket_name", "my-bucket"

      expect(described_class.new.bucket_name).to eql("my-bucket")
    end

    it "raises an error if bucket name wasn't given and terraform isn't set up" do
      FileUtils.rm_rf("./terraform")
      expect{described_class.new}.to raise_error(ArgumentError, "bucket_name required")
    end

    it "raises an error if bucket name wasn't given and terraform doesn't output `baking_rack_bucket_name`" do
      stub_terraform_command "output -raw baking_rack_bucket_name", "No outputs found"
      expect{described_class.new}.to raise_error(ArgumentError, "bucket_name required")
    end
  end

  private

  def deployer(**kargs)
    described_class.new(**{bucket_name:}.merge(kargs))
  end

  def deploy_file(path)
    BakingRack::Deployer::DeployFile.new(build_directory, path)
  end

  def write_file(path, content)
    FileUtils.mkdir_p(File.join(build_directory, File.dirname(path)))
    File.write(File.join(build_directory, path), content)
  end

  def expect_s3_put(path:, **properties)
    object = double("object")

    expect(s3_bucket).to receive(:object).with(path).and_return(object)
    expect(object).to receive(:put).with(properties)
  end

  def expect_no_s3_put
    expect(s3_bucket).not_to receive(:object)
  end
end
