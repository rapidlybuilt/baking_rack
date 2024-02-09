require "open3"

module TerraformSupport
  def self.included(base)
    base.class_eval do
      before do
        FileUtils.mkdir_p("terraform")
      end

      after do
        FileUtils.rm_rf("terraform")
      end
    end
  end

  def stub_terraform_command(command, stdout)
    expect(Open3).to receive(:capture3).with("terraform #{command}").and_return([stdout, nil, nil])
  end
end
