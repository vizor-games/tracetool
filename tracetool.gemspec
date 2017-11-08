require_relative './lib/tracetool/version'

Gem::Specification.new do |s|
  s.name        = 'tracetool'
  s.version     = Tracetool::Version.join('.')
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'Tracetool'
  s.description = 'Unpack vizor mobile traces'
  s.authors     = ['ilya.arkhanhelsky']
  s.email       = 'ilya.arkhanhelsky@vizor-interactive.com'
  s.files       = Dir['lib/**/*']
  s.executables = ['tracetool']
  s.license     = 'MIT'
end
