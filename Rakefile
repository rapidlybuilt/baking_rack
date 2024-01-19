# frozen_string_literal: true

require "rspec/core/rake_task"
require "rubocop/rake_task"

RuboCop::RakeTask.new

task :default do
  RSpec::Core::RakeTask.new(:spec)
  Rake::Task["spec"].execute
  Rake::Task["rubocop"].execute
end
