# frozen_string_literal: true

require "rack"

module BakingRack
  # rubocop:disable Metrics/ClassLength
  class Builder
    include Observable

    attr_accessor :app
    attr_accessor :build_directory
    attr_accessor :domain_name
    attr_accessor :public_directory
    attr_accessor :index_filename

    attr_writer :uri

    def initialize(app:, domain_name:, build_directory: BakingRack.config.build_directory)
      @app = app
      @build_directory = File.expand_path(build_directory)
      @domain_name = domain_name
      @index_filename = "index.html"

      @static_routes = []
      @static_route_blocks = []
      @static_routes_ready = true

      yield self if block_given?
    end

    def define_static_routes(&block)
      # HACK: delay the running of the block so the web framework
      # loads the route helpers.
      @static_routes_ready = false

      @static_route_blocks << block
    end

    def static_routes
      raise ArgumentError, "use #define_static_routes for a block" if block_given?

      return @static_routes if @static_routes_ready

      init_static_routes
      @static_routes
    end

    def run
      notify_observers :build_started
      run_build
      notify_observers :build_finished
    end

    def clean
      notify_observers :clean_started
      run_clean
      notify_observers :clean_finished
    end

    def uri
      @uri || URI("https://#{domain_name}")
    end

  private

    def run_build
      copy_public_directory if public_directory
      build_static_routes
    end

    def run_clean
      remove_directory(build_directory)
    end

    def copy_public_directory
      copy_directory(public_directory)
    end

    def copy_directory(directory, destination_folder = "/")
      notify_observers :build_directory_copied, directory, destination_folder

      # cannot use FileUtils.cp_r because we want to guarantee:
      # public/404.html -> build_directory/404.html
      # NOT build_directory/public/404.html

      pattern = File.join(directory, "*")

      FileUtils.mkdir_p(build_directory)
      Dir.glob(pattern, File::FNM_DOTMATCH).each do |path|
        basename = File.basename(path)
        next if %w[. ..].include?(basename)

        if File.directory?(path)
          FileUtils.cp_r(path, File.join(build_directory, destination_folder))
        else
          dest = File.join(build_directory, destination_folder, basename)
          FileUtils.cp(path, dest)
        end
      end
    end

    def remove_directory(directory)
      notify_observers :build_directory_removed, directory
      FileUtils.rm_rf(directory)
    end

    def remove_file(path)
      notify_observers :build_file_removed, path
      FileUtils.rm_f(path)
    end

    def static_routes_context
      StaticRoutesContext.new(index_filename, @static_routes)
    end

    def init_static_routes
      @static_routes = []
      context = static_routes_context

      @static_route_blocks.each do |block|
        context.instance_eval(&block)
      end

      @static_routes_ready = true
    end

    def build_static_routes
      notify_observers :build_static_routes_started, static_routes

      static_routes.each do |static_route|
        build_static_route(static_route)
      end

      notify_observers :build_static_routes_finished, static_routes
    end

    def build_static_route(static_route)
      status, headers, body = request_static_route(static_route)

      if [301, 302].include?(status.to_i)
        write_redirect(static_route.filepath, headers["location"])
      else
        write_file(static_route.filepath, body)
      end
    end

    def request_static_route(static_route)
      uri = self.uri.merge(static_route.path)
      status = static_route.status

      request = self.class.generate_request(uri)
      response = app.call(request)

      notify_observers(:static_route_requested, static_route:, request:, response:)

      unless response[0].to_i == status.to_i
        raise UnexpectedStatusCode, "got #{response[0]}, expected #{status} for #{uri}"
      end

      self.class.deconstruct_response(response)
    end

    def write_file(path, content)
      filename = File.expand_path(File.join(build_directory, path))

      # prevent URLs from navigating outside the output directory with ../.. cleverness.
      raise ArgumentError, "invalid URL: #{path}" unless filename.start_with?(build_directory)

      FileUtils.mkdir_p(File.dirname(filename))
      File.write(filename, content)
    end

    def write_redirect(path, location)
      write_file(path, redirect_file_content(location))
    end

    def redirect_file_content(location)
      BakingRack.redirect_file_content(location)
    end

    class StaticRoute # :nodoc:
      attr_accessor :path
      attr_accessor :status
      attr_accessor :headers
      attr_accessor :filepath

      def initialize(path, status:, headers:, filepath: nil)
        @path = path
        @status = status
        @headers = headers
        @filepath = filepath
      end
    end

    class StaticRoutesContext # :nodoc:
      def initialize(index_filename, routes)
        @index_filename = index_filename
        @routes = routes
      end

      def get(path, status: 200, headers: {}, filepath: nil)
        filepath ||= path.end_with?("/") ? File.join(path, @index_filename) : path

        @routes << StaticRoute.new(path, status:, headers:, filepath:)
      end
    end

    class << self
      def run(...)
        new(...).run
      end

      def generate_request(uri)
        {
          # https://github.com/rack/rack/blob/d3225f7c201320ed272a2fa7b000c5850e4a5f88/lib/rack/mock.rb#L43-L50
          Rack::RACK_VERSION => Rack.release,
          Rack::RACK_INPUT => StringIO.new,
          Rack::RACK_ERRORS => StringIO.new,
          # Rack::RACK_MULTITHREAD  => true,
          # Rack::RACK_MULTIPROCESS => true,
          # Rack::RACK_RUNONCE      => false,

          # https://github.com/rack/rack/blob/d3225f7c201320ed272a2fa7b000c5850e4a5f88/lib/rack.rb#L17-L27
          Rack::HTTP_HOST => uri.host,
          Rack::HTTP_PORT => uri.port,
          Rack::HTTPS => "on",
          Rack::PATH_INFO => uri.path,
          Rack::REQUEST_METHOD => "GET",
          Rack::SCRIPT_NAME => "",
          Rack::QUERY_STRING => uri.query, # NOTE: multiple query strings values won't work
          Rack::SERVER_PROTOCOL => "HTTP/1.1",
          Rack::SERVER_NAME => uri.host,
          Rack::SERVER_PORT => uri.port,
        }
      end

      def deconstruct_response(response)
        # Standardize response header names to lowercase
        headers = response[1].to_h.transform_keys(&:downcase)

        # Gather the Rack body array into a single string
        body = String.new
        response[2].each { |s| body << s }

        [response[0], headers, body]
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
