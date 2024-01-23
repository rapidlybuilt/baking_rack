module BakingRack
  class Railtie < ::Rails::Railtie
    rake_tasks do
      require "baking_rack/rake_task"
      BakingRack::RakeTask.new
    end
  end
end
