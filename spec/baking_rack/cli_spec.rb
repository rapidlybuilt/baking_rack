# frozen_string_literal: true

require "spec_helper"

RSpec.describe BakingRack::CLI do
  include ThorSupport

  let(:builder) { BakingRack::Builder.new(app: basic_app, domain_name:) }
  let(:deployer) { BakingRack::Deployer.new }

  before do
    BakingRack.config.builder = builder
    BakingRack.config.deployer = deployer
  end

  describe "build" do
    let(:output) { capture(:stdout) { subject.build } }

    it "runs the builder" do
      expect(output).to include("Built 0 static routes")
    end

    it "raises an error when builder isn't set" do
      BakingRack.config.builder = nil
      expect{output}.to raise_error("You must set BakingRack.config.builder before running!")
    end
  end

  describe "deploy" do
    let(:output) { capture(:stdout) { subject.deploy } }

    it "runs the deployer" do
      expect(output).to include("Uploaded 0 files")
    end

    it "raises an error when deployer isn't set" do
      BakingRack.config.deployer = nil
      expect{output}.to raise_error("You must set BakingRack.config.deployer before running!")
    end
  end

  describe "publish" do
    let(:output) { capture(:stdout) { subject.publish } }

    it "runs the builder and deployer" do
      expect(output).to include("Built 0 static routes")
      expect(output).to include("Uploaded 0 files")
    end
  end

  describe "clean" do
    let(:output) { capture(:stdout) { subject.clean } }

    before do
      subject.options = OpenStruct.new(verbose?: true)
    end

    it "runs clean on the builder" do
      expect(output).to include("Clean started")
    end

    it "raises an error when builder isn't set" do
      BakingRack.config.builder = nil
      expect{output}.to raise_error("You must set BakingRack.config.builder before running!")
    end
  end

  describe "prune" do
    let(:output) { capture(:stdout) { subject.prune } }

    it "raises an error when deployer isn't set" do
      BakingRack.config.deployer = nil
      expect { output }.to raise_error("You must set BakingRack.config.deployer before running!")
    end

    it "says prune is not supported when deployer does not support prune" do
      expect(output).to include("Prune is not supported by this deployer.")
    end

    context "when deployer supports prune" do
      let(:pruneable_deployer) do
        double(
          "pruneable_deployer",
          supports_prune?: true,
          build_directory: BakingRack.config.build_directory,
          local_paths: [],
          remote_paths: [],
          add_observer: nil,
          delete_remote_path: nil,
        )
      end

      before do
        BakingRack.config.deployer = pruneable_deployer
        FileUtils.mkdir_p(BakingRack.config.build_directory)
      end

      it "raises when build directory does not exist" do
        allow(pruneable_deployer).to receive(:build_directory).and_return("/nonexistent/path")
        expect { subject.prune }.to raise_error(BakingRack::DirectoryMissingError)
      end

      it "says Nothing to prune when remote has no extra files" do
        allow(pruneable_deployer).to receive(:local_paths).and_return(%w[index.html])
        allow(pruneable_deployer).to receive(:remote_paths).and_return(%w[index.html])
        expect(output).to include("Nothing to prune.")
      end

      it "lists missing files and aborts when user declines" do
        allow(pruneable_deployer).to receive(:remote_paths).and_return(%w[old.html])
        allow(subject).to receive(:ask).and_return("n")
        expect(output).to include("The following files exist on the remote but not in the build directory:")
        expect(output).to include("old.html")
        expect(output).to include("Aborted.")
        expect(pruneable_deployer).not_to have_received(:delete_remote_path)
      end

      it "deletes missing files when user confirms" do
        allow(pruneable_deployer).to receive(:remote_paths).and_return(%w[old.html])
        allow(subject).to receive(:ask).and_return("y")
        out = capture(:stdout) { subject.prune }
        expect(out).to include("Deleted 1 file(s).")
        expect(pruneable_deployer).to have_received(:delete_remote_path).with("old.html", dry_run: false)
      end

      it "reports dry run and does not delete when dry_run is set" do
        subject.options = OpenStruct.new(verbose?: false, dry_run?: true)
        allow(pruneable_deployer).to receive(:remote_paths).and_return(%w[old.html])
        allow(subject).to receive(:ask).and_return("y")
        out = capture(:stdout) { subject.prune }
        expect(out).to include("Dry run: would delete 1 file(s).")
        expect(out).to include("Done (dry run).")
        expect(pruneable_deployer).to have_received(:delete_remote_path).with("old.html", dry_run: true)
      end
    end
  end

  describe "help" do
    let(:output) { capture(:stdout) { subject.help } }

    it "outputs available commands" do
      expect(output).to include("Builds and deploys all static webpages")
    end
  end
end
