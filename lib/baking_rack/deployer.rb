# frozen_string_literal: true

require_relative "mime_types"

module BakingRack
  class Deployer
    include Observable

    attr_reader :build_directory
    attr_reader :ignored_filenames

    def initialize(build_directory: BakingRack.config.build_directory,
                   ignored_filenames: BakingRack.config.ignored_filenames)
      @build_directory = build_directory
      @ignored_filenames = ignored_filenames
    end

    def run(dry_run: false, force_all: false)
      @dry_run = dry_run
      @force_all = force_all

      notify_observers :deploy_started
      ensure_build_directory

      source_files.each do |path|
        file = DeployFile.new(build_directory, path)

        if ignored?(file) || (!force_all? && unchanged?(file))
          skip_file(file)
        else
          upload_file(file)
        end
      end
      notify_observers :deploy_finished
    end

    def force_all?
      @force_all
    end

    def dry_run?
      @dry_run
    end

  private

    def skip_file(file)
      notify_observers :deploy_file_skipped, file
    end

    def upload_file(file)
      notify_observers :file_deployed, file
    end

    def content_type_for(path)
      extension = File.extname(path)
      extension = extension[1..] if extension.start_with?(".")

      MIME::Types.type_for(extension).first&.content_type
    end

    def source_files
      pattern = File.join(build_directory, "**", "*")
      files = Dir.glob(pattern, File::FNM_DOTMATCH)

      files.delete_if do |path|
        File.directory?(path)
      end

      files.collect do |file|
        file[build_directory.length + 1..]
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

    def ensure_build_directory
      return if File.directory?(build_directory)

      raise DirectoryMissingError, build_directory
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
