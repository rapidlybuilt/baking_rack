# frozen_string_literal: true

module BakingRack
  module Rails
    class Builder < BakingRack::Builder
      class InvalidRailsEnvironmentError < Error; end

      def initialize(app: ::Rails.application,
                     build_directory: BakingRack.config.build_directory,
                     domain_name: nil, &block)
        super(app:, build_directory:, domain_name:, &block)

        self.public_directory = "public"
      end

      def domain_name
        super || default_domain_name || raise(ArgumentError, "domain_name required")
      end

    private

      def run_build
        ensure_production_environment
        bundle_exec "rake assets:precompile"
        remove_file "public/assets/.manifest.json"
        super
      end

      def run_clean
        bundle_exec "rake assets:clobber"
        super
      end

      def static_routes_context
        StaticRoutesContext.new(app, index_filename, @static_routes)
      end

      def default_domain_name
        app.config.hosts.first
      end

      def bundle_exec(command)
        system({ "RAILS_ENV" => "production" }, "bundle exec #{command}")
      end

      def ensure_production_environment
        return if ::Rails.env.production?

        raise InvalidRailsEnvironmentError, ::Rails.env.to_s
      end

      class StaticRoutesContext < BakingRack::Builder::StaticRoutesContext
        def initialize(app, *args, **kargs)
          super(*args, **kargs)
          @app = app

          singleton_class.include(@app.routes.url_helpers)
        end

        def get_other_rails_routes(except: [])
          @app.routes.routes.each do |route|
            next if ignored_route?(route, except:)

            path = render_route_spec(route.path.spec)
            get(path, status: infer_route_status(route)) unless already_added?(path)
          end
        end

        def ignored_route?(route, except: [])
          name = route.name.to_s
          path = route.path.spec.to_s

          # explicitly skipped
          return true if except.include?(name) || except.include?(path)

          # static sites only support GET requests
          return true unless route.verb == "GET"

          # Rails adds a bunch of routes
          return true if rails_default_route?(name, path)

          # this method doesn't support path variables
          return true unless route.parts == [] || route.parts == [:format]

          false
        end

        def rails_default_route?(name, path)
          name.start_with?("rails_") ||
            name.start_with?("turbo_") ||
            path == "/cable"
        end

        def already_added?(path)
          @routes.any? { |r| r.path == path }
        end

        def render_route_spec(spec)
          path = spec.to_s

          format = "(.:format)"
          if path.end_with?(format)
            path = path.sub(format, "")

            ext = File.extname(path)
            path += ".html" if ext == ""
          end

          path
        end

        def infer_route_status(route)
          # HACK: how else to backward engineer this?
          if route.app.respond_to?(:app) && route.app.app.is_a?(ActionDispatch::Routing::PathRedirect)
            route.app.app.status
          else
            200
          end
        end
      end
    end
  end
end
