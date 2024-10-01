# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Mime Types" do
  it "registers turbo_stream" do
    expect(MIME::Types.type_for("turbo_stream").first.to_s).to eql("text/vnd.turbo-stream.html")
  end
end
