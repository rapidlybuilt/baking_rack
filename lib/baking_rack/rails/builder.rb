module BakingRack
  module Rails
    class Builder < BakingRack::Builder
      def initialize(app: ::Rails.application, output_directory: "tmp/baking_rack", domain_name: default_domain_name(app), &block)
        super(app:, output_directory:, domain_name:, &block)

        self.public_directory = "public"
      end

      def run
        bundle_exec "rake assets:precompile"
        super
      end

      def clean
        bundle_exec "rake assets:clobber"
        super
      end

    private

      # TODO: helper to add ALL Rails routes as 200 or 301
      def static_routes_context
        context = super
        context.singleton_class.include(app.routes.url_helpers)
        context
      end

      def default_domain_name(app)
        app.config.hosts.first
      end

      def bundle_exec(command)
        system({"RAILS_ENV" => "production"}, "bundle exec #{command}")
      end
    end
  end
end
