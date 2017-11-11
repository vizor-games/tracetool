begin
  require 'rubocop/rake_task'
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:rspec)
  RuboCop::RakeTask.new(:lint)
rescue LoadError => x
  puts 'Some gems where missing. Fake tasks will be generated'
  puts "Error: #{x.message}"

  task(:lint) {}
  task(:rspec) {}
end

require_relative 'lib/version'

task :default => :check

desc 'Run tests and linter'
task :check => %i[rspec lint]

desc 'Generate documentation'
task :doc do
  puts `yard --doc - Readme.md Changelog.md`
end

namespace :gem do
  GEMNAME = "tracetool-#{Tracetool::Version}.gem".freeze
  desc "Build #{GEMNAME}"
  task :build => :check do
    puts `gem build tracetool.gemspec`
  end

  desc "Install #{GEMNAME}"
  task :install => :build do
    puts `gem install #{GEMNAME}`
  end
end
