# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::AwsS3::Deployer do
  let(:s3) { double(:s3, bucket: s3_bucket) }
  let(:s3_bucket) { double(:s3_bucket) }
  let(:bucket_name) { "my-bucket" }

  before do
    allow(Aws::S3::Resource).to receive(:new).and_return(s3)
    @original_s3_prefix = ENV["S3_PREFIX"]
    ENV.delete("S3_PREFIX")
  end

  after do
    if @original_s3_prefix.nil?
      ENV.delete("S3_PREFIX")
    else
      ENV["S3_PREFIX"] = @original_s3_prefix
    end
  end

  it "writes new files to S3" do
    write_file "favicon.png", "BINARY"

    expect(s3_bucket).to receive(:objects).with(no_args).and_return([])
    expect_s3_put(
      path: "favicon.png",
      acl: "public-read",
      body: "BINARY",
      cache_control: "public,max-age=10",
      content_type: "image/png"
    )

    deployer.run
  end

  it "writes modified files to S3" do
    write_file "favicon.png", "BINARY"

    expect(s3_bucket).to receive(:objects).with(no_args).and_return([
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

    expect(s3_bucket).to receive(:objects).with(no_args).and_return([
      double(key: "favicon.png", etag: Digest::MD5.hexdigest("BINARY").inspect),
    ])

    expect_no_s3_put

    deployer.run
  end

  it "places a long cache time on fingerprinted files" do
    write_file "favicon-00bfe90b789ca3d522ceb4d3dc728007.png", "BINARY"

    expect(s3_bucket).to receive(:objects).with(no_args).and_return([
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

    expect(s3_bucket).to receive(:objects).with(no_args).and_return([])

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

    expect(s3_bucket).to receive(:objects).with(no_args).and_return([])
    expect_no_s3_put

    deployer.run(dry_run: true)
  end

  describe "text charset" do
    before { write_file "index.html", "<p>Hi!</p>" }
    
    it "includes charset for text content types by default" do
      expect(s3_bucket).to receive(:objects).with(no_args).and_return([])
      expect_s3_put(
        path: "index.html",
        acl: "public-read",
        body: "<p>Hi!</p>",
        cache_control: "public,max-age=10",
        content_type: "text/html; charset=utf-8"
      )

      deployer.run
    end

    it "allows skipping charset for text content types" do
      expect(s3_bucket).to receive(:objects).with(no_args).and_return([])
      expect_s3_put(
        path: "index.html",
        acl: "public-read",
        body: "<p>Hi!</p>",
        cache_control: "public,max-age=10",
        content_type: "text/html"
      )

      deployer.tap do |d|
        d.text_charset = nil
        d.run
      end
    end
  end

  describe "bucket_name argument" do
    it "doesn't raise an error when initializing the instance" do
      expect{described_class.new}.not_to raise_error
    end
  end

  describe "prefix" do
    let(:prefix) { "preview/pr-1" }

    it "uploads into the subdirectory" do
      write_file "favicon.png", "BINARY"

      expect(s3_bucket).to receive(:objects).with({ prefix: "preview/pr-1/" }).and_return([])
      expect_s3_put(
        path: "preview/pr-1/favicon.png",
        acl: "public-read",
        body: "BINARY",
        cache_control: "public,max-age=10",
        content_type: "image/png"
      )

      target = deployer(prefix:)
      expect(target.prefix).to eql("preview/pr-1/")
      target.run
    end

    it "skips unchanged files stored in the subdirectory" do
      write_file "favicon.png", "BINARY"

      expect(s3_bucket).to receive(:objects).with({ prefix: "preview/pr-1/" }).and_return([
        double(key: "preview/pr-1/favicon.png", etag: Digest::MD5.hexdigest("BINARY").inspect),
      ])
      expect_no_s3_put

      deployer(prefix:).run
    end

    it "normalizes slashes around the subdirectory" do
      write_file "index.html", "<p>Hi!</p>"

      expect(s3_bucket).to receive(:objects).with({ prefix: "preview/pr-1/" }).and_return([])
      expect_s3_put(
        path: "preview/pr-1/index.html",
        acl: "public-read",
        body: "<p>Hi!</p>",
        cache_control: "public,max-age=10",
        content_type: "text/html; charset=utf-8"
      )

      deployer(prefix: "/preview/pr-1/").run
    end

    it "reads S3_PREFIX when prefix is omitted" do
      ENV["S3_PREFIX"] = "from-env"
      write_file "index.html", "<p>Hi!</p>"

      expect(s3_bucket).to receive(:objects).with({ prefix: "from-env/" }).and_return([])
      expect_s3_put(
        path: "from-env/index.html",
        acl: "public-read",
        body: "<p>Hi!</p>",
        cache_control: "public,max-age=10",
        content_type: "text/html; charset=utf-8"
      )

      deployer.run
    end

    it "keeps an explicit blank prefix on the bucket root when S3_PREFIX is set" do
      ENV["S3_PREFIX"] = "from-env"
      write_file "index.html", "<p>Hi!</p>"

      expect(s3_bucket).to receive(:objects).with(no_args).and_return([])
      expect_s3_put(
        path: "index.html",
        acl: "public-read",
        body: "<p>Hi!</p>",
        cache_control: "public,max-age=10",
        content_type: "text/html; charset=utf-8"
      )

      target = deployer(prefix: "")
      expect(target.prefix).to be_nil
      target.run
    end

    it "returns prune paths relative to the subdirectory and deletes only those keys" do
      write_file "index.html", "<p>Hi!</p>"

      expect(s3_bucket).to receive(:objects).with({ prefix: "preview/pr-1/" }).and_return([
        double(key: "preview/pr-1/index.html", etag: "\"a\""),
        double(key: "preview/pr-1/old.html", etag: "\"b\""),
        double(key: "preview/pr-1/", etag: "\"dir\""),
      ])

      target = deployer(prefix:)
      expect(target.remote_paths).to contain_exactly("index.html", "old.html")

      object = double("object")
      expect(s3_bucket).to receive(:object).with("preview/pr-1/old.html").and_return(object)
      expect(object).to receive(:delete)
      expect(s3_bucket).not_to receive(:object).with("old.html")

      target.delete_remote_path("old.html")
    end

    it "refuses paths that would leave the subdirectory" do
      expect(s3_bucket).not_to receive(:objects)
      expect(s3_bucket).not_to receive(:object)

      target = deployer(prefix:)
      expect { target.delete_remote_path("../secret.html") }.to raise_error(ArgumentError)
      expect { target.delete_remote_path("/secret.html") }.to raise_error(ArgumentError)
      expect { target.delete_remote_path("foo/../../secret.html") }.to raise_error(ArgumentError)
    end

    it "stops when a listing contains a key outside the subdirectory" do
      write_file "index.html", "<p>Hi!</p>"

      expect(s3_bucket).to receive(:objects).with({ prefix: "preview/pr-1/" }).and_return([
        double(key: "other/secret.html", etag: "\"x\""),
      ])
      expect(s3_bucket).not_to receive(:object)

      expect { deployer(prefix:).run }.to raise_error(BakingRack::AwsS3::Prefix::OutsidePrefixError)
    end

    it "rejects a prefix that climbs out of the subdirectory" do
      expect { deployer(prefix: "..") }.to raise_error(ArgumentError)
      expect { deployer(prefix: "foo/../bar") }.to raise_error(ArgumentError)
      expect { deployer(prefix: "/") }.to raise_error(ArgumentError)
    end

    context "with a stubbed S3 client" do
      let(:client) { Aws::S3::Client.new(stub_responses: true, region: "us-east-1") }
      let(:body) { "<p>Hi!</p>" }

      before do
        allow(Aws::S3::Resource).to receive(:new).and_call_original
      end

      it "limits every S3 request to the subdirectory" do
        write_file "index.html", body
        write_file "assets/app.js", "alert(1)"

        client.stub_responses(:list_objects_v2, contents: [
          { key: "preview/pr-1/index.html", etag: Digest::MD5.hexdigest(body).inspect },
          { key: "preview/pr-1/old.html", etag: "\"stale\"" },
          { key: "preview/pr-1/", etag: "\"dir\"" },
        ])

        target = deployer(client:, prefix:)
        target.run
        expect(target.remote_paths).to contain_exactly("index.html", "old.html")
        target.delete_remote_path("old.html")

        calls = s3_calls(client)
        expect(calls).to include(
          { operation: :list_objects_v2, prefix: "preview/pr-1/", key: nil },
          { operation: :put_object, prefix: nil, key: "preview/pr-1/assets/app.js" },
          { operation: :delete_object, prefix: nil, key: "preview/pr-1/old.html" },
        )
        expect_calls_stay_inside(calls, "preview/pr-1/")
      end

      it "does not issue a write when the listing escapes the subdirectory" do
        write_file "index.html", body
        client.stub_responses(:list_objects_v2, contents: [
          { key: "secret.html", etag: "\"x\"" },
        ])

        expect { deployer(client:, prefix:).run }.to raise_error(BakingRack::AwsS3::Prefix::OutsidePrefixError)

        calls = s3_calls(client)
        expect(calls.map { |call| call[:operation] }).to eql([:list_objects_v2])
        expect_calls_stay_inside(calls, "preview/pr-1/")
      end

      it "does not call S3 when a delete path escapes the subdirectory" do
        target = deployer(client:, prefix:)

        expect { target.delete_remote_path("../secret.html") }.to raise_error(ArgumentError)
        expect { target.delete_remote_path("/secret.html") }.to raise_error(ArgumentError)
        expect(client.api_requests).to be_empty
      end
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

  def s3_calls(client)
    client.api_requests.map do |request|
      params = request[:params]
      {
        operation: request[:operation_name],
        prefix: params[:prefix],
        key: params[:key],
      }
    end
  end

  def expect_calls_stay_inside(calls, prefix)
    calls.each do |call|
      case call[:operation]
      when :list_objects_v2
        expect(call[:prefix]).to eql(prefix)
      when :put_object, :delete_object, :get_object, :head_object
        expect(call[:key]).to start_with(prefix)
      else
        raise "unexpected S3 operation #{call[:operation]}"
      end
    end
  end
end
