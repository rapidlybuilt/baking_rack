# frozen_string_literal: true

require "spec_helper"
require "open3"

RSpec.describe BakingRack::Observable do
  let(:instance) { MyObservable.new }
  let(:observer) { double("observer") }

  class MyObservable
    include BakingRack::Observable
  end

  before { instance.add_observer(observer) }

  it "allows removing the observer" do
    expect{instance.remove_observer(observer)}.to change{instance.observers.length}.by(-1)
  end

  it "allows listening to system commands" do
    command = "bundle exec rake something"
    stdout = "$STDOUT"
    stderr = "$STDERRO"
    status = double("status")

    expect(observer).to receive(:system_exec_started).with(command, env: {})
    expect(observer).to receive(:system_exec_finished).with(command, env: {}, stdout:, stderr:, status:)

    expect(Open3).to receive(:capture3).with(command).and_return([stdout, stderr, status])

    instance.system(command)
  end
end
