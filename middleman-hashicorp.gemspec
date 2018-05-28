# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

`cd #{File.dirname(__FILE__)}/lib/middleman-hashicorp/reshape && npm i`
puts 'post_install called for carrot/middleman-hashicorp'

require 'middleman-hashicorp/version'

Gem::Specification.new do |spec|
  spec.name          = 'middleman-hashicorp'
  spec.version       = Middleman::HashiCorp::VERSION
  spec.authors       = ['Seth Vargo']
  spec.email         = ['sethvargo@gmail.com']
  spec.summary       = 'A series of helpers for consistency among HashiCorp\'s middleman sites'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/hashicorp/middleman-hashicorp'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3'

  # Middleman
  spec.add_dependency 'middleman',            '~> 4.2'
  spec.add_dependency 'middleman-livereload', '~> 3.4'
  spec.add_dependency 'middleman-syntax',     '~> 3.0'

  # Dato
  spec.add_dependency 'middleman-dato'

  # Rails
  spec.add_dependency 'nokogiri',      '~> 1.8'
  spec.add_dependency 'activesupport', '~> 5.0'

  # Assets
  spec.add_dependency 'redcarpet', '~> 3.3'

  # Development dependencies
  spec.add_development_dependency 'rspec',   '~> 3.5'
  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake',    '~> 11.3'
end
