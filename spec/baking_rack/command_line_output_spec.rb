# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::CommandLineOutput do
  let(:io) { double("io", puts: nil) }
  let(:clo) { BakingRack::CommandLineOutput.new(io:, verbose: true) }

  describe "system events" do
    it "writes the env in front of the command" do
      expect(io).to receive(:puts).with(colorize :yellow, "RAILS_ENV=production bundle exec rake")

      clo.system_exec_started("bundle exec rake", env: { "RAILS_ENV" => "production" })
    end

    it "handles system_exec_finished" do
      stdout = "STDOUT"
      stderr = "STDERR"

      expect(io).to receive(:puts).with(stdout)
      expect(io).to receive(:puts).with(stderr)

      clo.system_exec_finished("bundle exec rake", stdout:, stderr:, status: double("status"))
    end
  end
end
