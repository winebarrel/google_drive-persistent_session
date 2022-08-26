# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'google_drive/persistent_session/version'

Gem::Specification.new do |spec|
  spec.name          = 'google_drive-persistent_session'
  spec.version       = GoogleDrive::PersistentSession::VERSION
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sugawara@winebarrel.jp']
  spec.summary       = %q{Persist credential for google-drive-ruby.}
  spec.description   = %q{Persist credential for google-drive-ruby.}
  spec.homepage      = 'https://github.com/winebarrel/google_drive-persistent_session'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'google_drive', '>= 3.0.7'
  spec.add_dependency 'highline'
  spec.add_dependency 'webrick'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
