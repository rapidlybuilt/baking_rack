module BakingRackSupport
  def self.included(base)
    base.class_eval do
      let(:build_directory) { BakingRack.config.build_directory }
      let(:domain_name) { "example.com" }

      let(:basic_app) do
        # Rack app that returns HTML contenet for all URLs
        Proc.new do |env|
          ["200", {"Content-Type" => "text/html"}, [html_content]]
        end
      end

      before do
        FileUtils.mkdir_p(build_directory)
      end

      after do
        BakingRack.config.builder = nil
        BakingRack.config.deployer = nil
        FileUtils.rm_rf(build_directory)
      end
    end
  end
end

RSpec.configure do |config|
  config.include BakingRackSupport
end
