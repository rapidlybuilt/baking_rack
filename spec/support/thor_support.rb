module ThorSupport
  # https://github.com/docwhat/homedir/blob/homedir3/spec/spec_helper.rb#L27-L47

  # Captures the output for analysis later
  #
  # @example Capture `$stderr`
  #
  #     output = capture(:stderr) { $stderr.puts "this is captured" }
  #
  # @param [Symbol] stream `:stdout` or `:stderr`
  # @yield The block to capture stdout/stderr for.
  # @return [String] The contents of $stdout or $stderr
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

  def thor_options(command_name, options = {})
    command_options = subject.class.commands[command_name].options

    hash = command_options.each_with_object({}) do |(key, opt), h|
      h[key.to_s] =  options[key] || options[key.to_s] || opt.default
    end

    OpenStruct.new(hash)
  end
end
