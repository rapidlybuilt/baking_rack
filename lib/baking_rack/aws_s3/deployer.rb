# frozen_string_literal: true

require "aws-sdk-s3"
require "digest"

module BakingRack
  module AwsS3
    class Deployer < BakingRack::Deployer
      attr_reader :acl

      def initialize(client: nil, bucket_name: nil, acl: "public-read", prefix: nil, **kargs)
        super(**kargs)

        @client = client
        @bucket_name = bucket_name
        @acl = acl
        # nil falls through to ENV["S3_PREFIX"], same as bucket_name and BUCKET_NAME.
        @prefix = Prefix.new(prefix.nil? ? ENV.fetch("S3_PREFIX", nil) : prefix)
      end

      # ENV["BUCKET_NAME"] when deploying from a CI/CD process.
      def bucket_name
        # load the default bucket name only if it's actually needed
        @bucket_name ||= ENV["BUCKET_NAME"] ||
                         raise(ArgumentError, "bucket_name required")
      end

      # Subdirectory inside the bucket, with a trailing slash. Nil deploys to the bucket root.
      # ENV["S3_PREFIX"] when deploying from a CI/CD process.
      def prefix
        return nil unless @prefix.scoped?

        @prefix.to_s
      end

      def upload_file(file)
        key = @prefix.object_key(file.path)

        headers_out = {
          acl:,
          body: file.content,
          content_type: content_type_with_charset_for(file.path) || "binary/octet-stream",
          cache_control: cache_control_for(file.path),
        }

        headers_out[:website_redirect_location] = file.redirect_location if file.redirect?

        s3_upload_file(file, key, headers_out)
        super
      end

      def supports_prune?
        true
      end

      # Paths relative to the prefix (or the bucket root when no prefix is set).
      def remote_paths
        s3_objects.keys
      end

      def delete_remote_path(path, dry_run: false)
        key = @prefix.object_key(path)
        return if dry_run

        s3_object(key).delete
      end

    private

      def unchanged?(file)
        md5 = Digest::MD5.hexdigest(file.content)

        # S3 returns etags surrounded by double-quotes
        s3_etag(file.path) == md5.inspect
      end

      def cache_control_for(key)
        fingerprinted?(key) ? "public,max-age=31556926" : "public,max-age=10"
      end

      def s3
        # (preferred method) AWS credentials are read from ENV
        @s3 ||= @client ? Aws::S3::Resource.new(client: @client) : Aws::S3::Resource.new
      end

      def s3_bucket
        @s3_bucket ||= s3.bucket(bucket_name)
      end

      def s3_etag(relative_path)
        s3_objects[relative_path]&.etag
      end

      def s3_objects
        @s3_objects ||= {}.tap do |hash|
          list_s3_objects.each do |obj|
            relative = @prefix.relative_path(obj.key)
            hash[relative] = obj if relative
          end
        end
      end

      def list_s3_objects
        @prefix.list(s3_bucket)
      end

      def s3_object(key)
        @prefix.object(s3_bucket, key)
      end

      def s3_upload_file(_file, key, properties)
        s3_object(key).put(properties) unless dry_run?
      end
    end
  end
end
