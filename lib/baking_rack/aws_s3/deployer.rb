# frozen_string_literal: true

require "aws-sdk-s3"
require "digest"

module BakingRack
  module AwsS3
    class Deployer < BakingRack::Deployer
      attr_reader :bucket_name

      def initialize(bucket_name:, **kargs)
        super(**kargs)

        @bucket_name = bucket_name
      end

      def upload_file(file)
        key = file.path

        headers_out = {
          acl: "public-read",
          body: file.content,
          content_type: content_type_for(key) || "binary/octet-stream",
          cache_control: cache_control_for(key),
        }

        headers_out[:website_redirect_location] = file.redirect_location if file.redirect?

        s3_upload_file(file, key, headers_out)
        super
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
        @s3 ||= Aws::S3::Resource.new
      end

      def s3_bucket
        @s3_bucket ||= s3.bucket(bucket_name)
      end

      def s3_etag(key)
        s3_objects[key]&.etag
      end

      def s3_objects
        @s3_objects ||= s3_bucket.objects.to_a.each_with_object({}) do |obj, hash|
          hash[obj.key] = obj
        end
      end

      def s3_upload_file(file, key, properties)
        s3_bucket.object(key).put(properties) unless dry_run?
      end
    end
  end
end
