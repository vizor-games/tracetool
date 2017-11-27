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

require_relative 'build/version'
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
    FileUtils.mkdir_p '.out'
    FileUtils.mv Dir['tracetool-*.gem'], '.out'
  end

  desc "Install #{GEMNAME}"
  task :install => :build do
    puts `gem install .out/#{GEMNAME}`
  end
end

namespace :version do
  desc 'bump version. version=x,y,z to describe increment'
  task :bump do
    version = ENV['version'].split(',').map(&:to_i)
    # Pad left with 0, so [1, 2] => [0, 1, 2]
    version = [0] * [0, (3 - version.length)].max + version
    Tracetool::Build::Bumper.new('lib/version.rb')
                            .bump(major: version[0], minor: version[1], patch: version[2])
  end
end
