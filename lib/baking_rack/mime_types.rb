# frozen_string_literal: true

require "mime-types"

{
  # hotwire
  "text/vnd.turbo-stream.html" => ["turbo_stream"],
}.each do |mime_type, extensions|
  type = MIME::Type.new("content-type" => mime_type) do |t|
    t.extensions = extensions
  end

  MIME::Types.add(type)

  next unless defined?(Mime::Type)

  extensions.each do |ext|
    Mime::Type.register mime_type, ext.to_sym
  end
end
