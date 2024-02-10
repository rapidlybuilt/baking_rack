# frozen_string_literal: true

module BakingRack
  module Commands
    # https://github.com/rails/thor/wiki/Subcommands#subcommands-that-work-correctly-with-help
    class SubCommandBase < Thor
      # rubocop:disable Style/OptionalBooleanParameter
      def self.banner(command, _namespace = nil, _subcommand = false)
        "#{basename} #{subcommand_prefix} #{command.usage}"
      end
      # rubocop:enable Style/OptionalBooleanParameter

      # rubocop:disable Style/MultilineBlockChain
      def self.subcommand_prefix
        name.gsub(/.*::/, "").gsub(/^[A-Z]/) do |match|
          match[0].downcase
        end.gsub(/[A-Z]/) { |match| "-#{match[0].downcase}" }
      end
      # rubocop:enable Style/MultilineBlockChain
    end
  end
end
