# frozen_string_literal: true

module BakingRack
  module AwsS3
    # Optional S3 subdirectory. When one is set, every key Baking Rack lists,
    # reads, writes, or deletes has to live under that prefix.
    class Prefix
      class OutsidePrefixError < BakingRack::Error; end

      def initialize(prefix)
        @prefix = normalize(prefix)
      end

      def scoped?
        !@prefix.nil?
      end

      def to_s
        @prefix.to_s
      end

      # ListObjectsV2 is limited to this subdirectory. Unscoped deploys list the bucket.
      def list(bucket)
        return bucket.objects unless scoped?
        raise OutsidePrefixError, "refusing to list the bucket without a prefix" if @prefix.empty?

        bucket.objects({ prefix: @prefix })
      end

      def object(bucket, key)
        assert_inside!(key)
        bucket.object(key)
      end

      def object_key(relative_path)
        relative = normalize_relative(relative_path)
        key = scoped? ? "#{@prefix}#{relative}" : relative
        assert_inside!(key)
        key
      end

      # Build-relative path for an object key returned by a listing.
      # The directory placeholder itself (`prefix/`) is ignored.
      def relative_path(object_key)
        key = object_key.to_s
        return nil if scoped? && key == @prefix

        assert_inside!(key)
        return key unless scoped?

        normalize_relative(key.delete_prefix(@prefix))
      end

      def assert_inside!(key)
        return if inside?(key)

        raise OutsidePrefixError, "Refusing to touch S3 key #{key.inspect} outside #{@prefix.inspect}"
      end

    private

      def inside?(key)
        key = key.to_s
        return true unless scoped?

        remainder = key.delete_prefix(@prefix)
        key.start_with?(@prefix) && !remainder.empty? && !remainder.start_with?("/")
      end

      def normalize(prefix)
        return nil if prefix.nil?

        value = prefix.to_s.strip
        return nil if value.empty?

        value = value.sub(%r{\A/+}, "").sub(%r{/+\z}, "")
        raise ArgumentError, "S3 prefix must name a subdirectory" if value.empty?

        segments = value.split("/", -1)
        validate_segments!(segments, label: "prefix")
        "#{segments.join("/")}/"
      end

      def normalize_relative(path)
        relative = path.to_s
        raise ArgumentError, "S3 path must be relative" if relative.start_with?("/")
        raise ArgumentError, "S3 path must not be empty" if relative.empty?

        segments = relative.split("/", -1)
        validate_segments!(segments, label: "path")
        segments.join("/")
      end

      def validate_segments!(segments, label:)
        segments.each do |segment|
          raise ArgumentError, "S3 #{label} must not contain empty, '.', or '..' segments" if blank_or_dot?(segment)
          raise ArgumentError, "S3 #{label} contains unsupported characters" if unsupported_chars?(segment)
        end
      end

      def blank_or_dot?(segment)
        segment.empty? || segment == "." || segment == ".."
      end

      def unsupported_chars?(segment)
        segment.include?("\\") || segment.match?(/[[:cntrl:]]/)
      end
    end
  end
end
