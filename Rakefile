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

task :default => :check

desc 'Run tests and linter'
task :check => %i[rspec lint]

desc 'Generate documentation'
task :doc do
  puts `yard --doc - Readme.md Changelog.md`
end
