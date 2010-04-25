require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name          = 'cloc'
  s.version       = '0.9.0'
  s.author        = 'Mooffie'
  s.email         = 'mooffie@gmail.com'
  s.platform      = Gem::Platform::RUBY
  s.homepage      = 'http://github.com/mooffie/cloc'
  s.summary       = 'Locates Ruby methods in C source files.'
  s.required_ruby_version = '>= 1.8.0'

  candidates = [] + Dir.glob("{bin,docs,lib,ext,tests,examples}/**/*")
  s.files = candidates.delete_if { |f| f =~ /(~|Makefile|\.o|\.so)$/ }
  #p s.files

  s.bindir        = 'bin'
  s.executables   = ['cloc']
  s.require_path  = 'lib'
end

if $0 == __FILE__
  Gem::Builder.new(spec).build
end
