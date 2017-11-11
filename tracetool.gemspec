require_relative './lib/version'

Gem::Specification.new do |s|
  s.name        = 'tracetool'
  s.version     = Tracetool::Version.to_s
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'Tracetool'
  s.description = 'Helper for unpacking Android and iOS traces'
  s.authors     = ['ilya.arkhanhelsky']
  s.email       = 'ilya.arkhanhelsky@vizor-games.com'
  s.homepage    = 'https://github.com/vizor-games/tracetool'
  s.files       = Dir['lib/**/*']
  s.executables = ['tracetool']
  s.license     = 'MIT'

  s.add_runtime_dependency 'powerpack', '0.1.1'
end
