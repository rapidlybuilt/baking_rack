module TerraformSupport
  def stub_terraform_files(filenames)
    allow(Dir).to receive(:glob).with("terraform/*.tfvars").and_return(filenames)
  end
end

RSpec.configure do |config|
  config.include TerraformSupport
end
