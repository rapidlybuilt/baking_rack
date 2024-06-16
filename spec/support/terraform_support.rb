require "open3"

BakingRack.config.terraform_directory = "tmp/terraform"

module TerraformSupport
  def self.included(base)
    base.class_eval do
      let(:terraform_directory) { BakingRack.config.terraform_directory }

      before do
        FileUtils.mkdir_p(terraform_directory)
      end

      after do
        FileUtils.rm_rf(terraform_directory)
      end
    end
  end

  def stub_terraform_command(command, stdout, stderr = nil, status = nil)
    expect(Open3).to receive(:capture3).with("terraform #{command}").and_return([stdout, stderr, status])
  end
end
