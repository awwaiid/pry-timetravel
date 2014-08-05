require 'rspec/core/rake_task'

task :default => :test
task :spec => :test

RSpec::Core::RakeTask.new(:test)

task :build do
  sh 'gem build *.gemspec'
end

task :install => :build do
  sh 'gem install *.gem'
end
