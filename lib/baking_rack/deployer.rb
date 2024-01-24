# frozen_string_literal: true

require "mime-types"

module BakingRack
  class Deployer
    attr_reader :source_directory
    attr_reader :ignored_filenames

    def initialize(source_directory:, ignored_filenames: %w[.DS_Store], force_all: false)
      @source_directory = source_directory
      @ignored_filenames = ignored_filenames
      @force_all = force_all
    end

    def run
      source_files.each do |path|
        file = DeployFile.new(source_directory, path)

        upload_file(file) unless ignored?(file) || (!force_all? && unchanged?(file))
      end
    end

    def force_all?
      @force_all
    end

  private

    def upload_file(file)
      raise NotImplementedError, "#{self.class.name} must implement #upload_file"
    end

    def content_type_for(path)
      extension = File.extname(path)
      extension = extension[1..] if extension.start_with?(".")

      MIME::Types.type_for(extension).first&.content_type
    end

    def source_files
      pattern = File.join(source_directory, "**", "*")
      files = Dir.glob(pattern, File::FNM_DOTMATCH)

      files.delete_if do |path|
        File.directory?(path)
      end

      files.collect do |file|
        file[source_directory.length + 1..]
      end
    end

    def ignored?(file)
      filename = File.basename(file.path)

      ignored_filenames.include?(filename)
    end

    def unchanged?(_file)
      false # subclasses can implement this
    end

    def fingerprinted?(path)
      !(File.basename(path) =~ /[0-9a-f]{16}/).nil?
    end

    class DeployFile
      attr_reader :directory
      attr_reader :path

      def initialize(directory, path)
        @directory = directory
        @path = path
      end

      def content
        @content ||= File.read(File.join(directory, path))
      end

      def redirect?
        !!redirect_location
      end

      def redirect_location
        pattern = BakingRack.redirect_file_content("(.+)")
        regex = Regexp.new(pattern)
        ::Regexp.last_match(1) if content =~ regex
      rescue ArgumentError
        nil
      end

      def ==(other)
        other.class == self.class && other.directory == directory && other.path == path
      end
    end

    class << self
      def run(**kargs)
        new(**kargs).run
      end
    end
  end
end
