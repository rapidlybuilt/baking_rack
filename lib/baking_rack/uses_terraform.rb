# frozen_string_literal: true

module BakingRack
  module UsesTerraform
    class Error < BakingRack::Error; end

    def terraform_directory
      BakingRack.config.terraform_directory
    end

    def terraform_setup?
      File.directory?(terraform_directory)
    end

    def read_terraform_output_value(name)
      return unless terraform_setup?

      stdout = capture_terraform_command("output -raw #{name}")
      stdout = nil if stdout.empty? || stdout.include?("No outputs found")
      stdout
    end

    def capture_terraform_command(name)
      Dir.chdir(terraform_directory) do
        require "open3"

        command = "terraform #{name}"
        stdout, stderr = Open3.capture3(command)

        if stdout == "" && !stderr.to_s.empty?
          warn stderr
          raise Error, "command errored: #{command}"
        end

        stdout
      end
    end
  end
end
