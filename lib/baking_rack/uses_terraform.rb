module BakingRack
  module UsesTerraform
    def terraform_directory
      BakingRack.config.terraform_directory
    end

    def terraform_setup?
      File.directory?(terraform_directory)
    end

    def read_terraform_output_value(name)
      return unless terraform_setup?

      stdout, stderr, status = capture_terraform_command("output -raw #{name}")
      stdout = nil if stdout.empty? || stdout.include?("No outputs found")
      stdout
    end

    def required_terraform_output_value(name)
      read_terraform_output_value(name) || raise(TerraformOutputNotFoundError, name)
    end

    def capture_terraform_command(name)
      Dir.chdir(terraform_directory) do
        require "open3"
        Open3.capture3("terraform #{name}")
      end
    end
  end
end
