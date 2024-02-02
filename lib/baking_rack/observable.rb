module BakingRack
  module Observable
    def observers
      @observers ||= []
    end

    def add_observer(observer)
      observers << observer
    end

    def remove_observer(observer)
      observers.delete(observer)
    end

    def notify_observers(event, *args, **kargs)
      args = [self] if args.empty? && kargs.empty?

      observers.each do |observer|
        observer.send(event, *args, **kargs) if observer.respond_to?(event)
      end
    end

    def system(*args)
      require "open3"
      env, command = args[0].is_a?(Hash) ? [args[0], args[1]] : [{}, args[0]]

      notify_observers(:system_exec_started, command, env:)

      stdout, stderr, status = Open3.capture3(*args)
      notify_observers(:system_exec_finished, command, env:, stdout:, stderr:, status:)
    end
  end
end
