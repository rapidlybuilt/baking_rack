# frozen_string_literal: true

require "set"

# it's a command and the code's actually pretty nice.

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/PerceivedComplexity

module BakingRack
  module Commands
    # TODO: prune expects the current build directory to have the most up-to-date version of the site.
    # i.e. it just needs to be run after a deploy. Too big of an assumption?
    class Prune
      def initialize(deployer:, shell:, dry_run: false)
        @deployer = deployer
        @shell = shell
        @dry_run = dry_run
      end

      def run
        unless @deployer.supports_prune?
          @shell.say("Prune is not supported by this deployer.", :red)
          return
        end

        raise DirectoryMissingError, @deployer.build_directory unless File.directory?(@deployer.build_directory)

        local = Set.new(@deployer.local_paths)
        remote = Set.new(@deployer.remote_paths)
        missing = (remote - local).sort

        if missing.empty?
          @shell.say("Nothing to prune.")
          return
        end

        @shell.say("The following files exist on the remote but not in the build directory:")
        missing.each { |path| @shell.say("  #{path}", :red) }
        @shell.say("")
        answer = @shell.ask("Delete these from the remote? (y/N)", default: "N")

        if answer =~ /\Ay(es)?\z/i
          @shell.say("Dry run: would delete #{missing.size} file(s).") if @dry_run
          missing.each { |path| @deployer.delete_remote_path(path, dry_run: @dry_run) }
          @shell.say(@dry_run ? "Done (dry run)." : "Deleted #{missing.size} file(s).")
        else
          @shell.say("Aborted.")
        end
      end
    end
  end
end

# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/PerceivedComplexity
