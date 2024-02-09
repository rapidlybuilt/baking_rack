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
        super || default_domain_name
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

      # TODO: helper to add ALL Rails routes as 200 or 301
      def static_routes_context
        context = super
        context.singleton_class.include(app.routes.url_helpers)
        context
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
    end
  end
end
