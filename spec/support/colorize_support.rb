require "colorized_string"

module ColorizeSupport
  def colorize(color, string)
    ColorizedString[string].colorize(color)
  end
end

RSpec.configure do |config|
  config.include ColorizeSupport
end
