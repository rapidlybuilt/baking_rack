require "mime-types"

{
  # hotwire
  "text/vnd.turbo-stream.html" => ["turbo_stream"],
}.each do |mime_type, extensions|
  type = MIME::Type.new(mime_type) do |type|
    type.extensions = extensions
  end

  MIME::Types.add(type)

  if defined?(Mime::Type)
    extensions.each do |ext|
      Mime::Type.register mime_type, ext.to_sym
    end
  end
end
