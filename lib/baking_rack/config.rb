# frozen_string_literal: true

module BakingRack
  class Config
    attr_accessor :build_directory
    attr_accessor :ignored_filenames

    # used by the CLI
    attr_accessor :builder
    attr_accessor :deployer

    def initialize(build_directory:, ignored_filenames: [], builder: nil, deployer: nil)
      @build_directory = build_directory
      @ignored_filenames = ignored_filenames

      @builder = builder
      @deployer = deployer
    end

    def define_static_routes(...)
      builder.define_static_routes(...)
    end
  end
end
