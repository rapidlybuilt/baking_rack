# frozen_string_literal: true

require "colorized_string"

module BakingRack
  class CommandLineOutput
    def initialize(io: $stdout, verbose: false)
      @io = io
      @verbose = verbose
    end

    def verbose?
      @verbose
    end

    # builder listener interface
    def build_started(builder)
      # HACK: don't display server logs unless in verbose mode
      ::Rails.logger.level = :warn if defined?(::Rails) && !verbose?

      debug { "#{colorize :yellow, "Build started"} #{builder.inspect}" }
    end

    def build_finished(_builder)
      debug { colorize :yellow, "Build finished" }
    end

    def clean_started(builder)
      debug { "#{colorize :yellow, "Clean started"} #{builder.inspect}" }
    end

    def clean_finished(_builder)
      debug { colorize :yellow, "Clean finished" }
    end

    def build_directory_copied(directory, destination_folder)
      debug { "#{colorize :yellow, "Directory copied"} #{directory} -> #{destination_folder}" }
    end

    def build_file_removed(path)
      debug { "#{colorize :yellow, "File removed"} #{path}" }
    end

    def build_directory_removed(directory)
      debug { "#{colorize :yellow, "Directory removed"} #{directory}" }
    end

    def build_static_routes_started(static_routes)
      debug { colorize :yellow, "Building #{static_routes.length} static routes" }
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def static_route_requested(static_route:, request:, response:)
      status = response[0]
      color = static_route.status.to_s == status.to_s ? :green : :red

      info { "#{colorize color, status.to_s} #{static_route.path}" }
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def build_static_routes_finished(static_routes)
      debug { colorize :yellow, "Built #{static_routes.length} static routes" }
    end

    # deployer listener interface
    def deploy_started(_deployer)
      debug { colorize :yellow, "Deploy started" }
    end

    def deploy_finished(_deployer)
      debug { colorize :yellow, "Deploy finished" }
    end

    def deploy_file_skipped(file)
      debug { "#{colorize :yellow, "Skipped "} #{file.path}" }
    end

    def file_deployed(file)
      info { "#{colorize :green, "Uploaded"} #{file.path}" }
    end

    # observable listener interface

    def system_exec_started(command, env: {})
      debug do
        env_string = env.inject("") do |s, (k, v)|
          s + "#{k}=#{v} "
        end

        colorize :yellow, "#{env_string}#{command}"
      end
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def system_exec_finished(_command, stdout:, stderr:, status:, env: {})
      debug { stdout }
      debug { stderr }
    end
    # rubocop:enable Lint/UnusedMethodArgument

  private

    def debug(msg = nil, &block)
      return unless verbose?

      @io.puts(msg || block.call)
    end

    def info(msg = nil, &block)
      @io.puts(msg || block.call)
    end

    def colorize(color, string)
      ColorizedString[string].colorize(color)
    end
  end
end
