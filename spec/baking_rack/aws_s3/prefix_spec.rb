# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::AwsS3::Prefix do
  describe "normalization" do
    it "treats a blank prefix as the whole bucket" do
      expect(described_class.new(nil)).not_to be_scoped
      expect(described_class.new("")).not_to be_scoped
      expect(described_class.new("   ")).not_to be_scoped
    end

    it "stores a subdirectory with a trailing slash" do
      expect(described_class.new("preview").to_s).to eql("preview/")
      expect(described_class.new("/preview/pr-1/").to_s).to eql("preview/pr-1/")
    end

    it "rejects prefixes that are not a subdirectory" do
      ["..", "foo/../bar", "foo/./bar", "foo//bar", "/", "\\secret", "foo/\nbaz"].each do |prefix|
        expect { described_class.new(prefix) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "keys" do
    subject(:prefix) { described_class.new("preview/pr-1") }

    it "joins build paths onto the subdirectory" do
      expect(prefix.object_key("index.html")).to eql("preview/pr-1/index.html")
      expect(prefix.object_key("assets/app.js")).to eql("preview/pr-1/assets/app.js")
    end

    it "maps listed keys back to build paths and ignores the directory placeholder" do
      expect(prefix.relative_path("preview/pr-1/assets/app.js")).to eql("assets/app.js")
      expect(prefix.relative_path("preview/pr-1/")).to be_nil
    end

    it "refuses keys outside the subdirectory" do
      bucket = double("bucket")
      expect(bucket).not_to receive(:object)
      expect(bucket).not_to receive(:objects)

      ["preview/pr-10/index.html", "other/secret.html", "preview/pr-1", "secret.html"].each do |key|
        expect { prefix.assert_inside!(key) }.to raise_error(described_class::OutsidePrefixError)
        expect { prefix.object(bucket, key) }.to raise_error(described_class::OutsidePrefixError)
        expect { prefix.relative_path(key) }.to raise_error(described_class::OutsidePrefixError)
      end
    end

    it "refuses relative paths that climb out" do
      expect { prefix.object_key("../secret.html") }.to raise_error(ArgumentError)
      expect { prefix.object_key("/secret.html") }.to raise_error(ArgumentError)
      expect { prefix.object_key("foo/../../secret.html") }.to raise_error(ArgumentError)
    end
  end

  describe "S3 calls" do
    it "lists only the subdirectory" do
      bucket = double("bucket")
      prefix = described_class.new("preview")

      expect(bucket).to receive(:objects).with({ prefix: "preview/" }).and_return(:listed)
      expect(bucket).not_to receive(:objects).with(no_args)

      expect(prefix.list(bucket)).to eql(:listed)
    end

    it "lists the bucket when no subdirectory is set" do
      bucket = double("bucket")

      expect(bucket).to receive(:objects).with(no_args).and_return(:listed)
      expect(described_class.new(nil).list(bucket)).to eql(:listed)
    end

    it "writes an object only after the key is inside the subdirectory" do
      bucket = double("bucket")
      object = double("object")
      prefix = described_class.new("preview")

      expect(bucket).to receive(:object).with("preview/index.html").and_return(object)
      expect(prefix.object(bucket, prefix.object_key("index.html"))).to eql(object)
    end
  end
end
