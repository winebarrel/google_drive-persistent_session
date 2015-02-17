# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'google_drive-persistent_session'
  spec.version       = '0.1.1'
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sgwr_dts@yahoo.co.jp']
  spec.summary       = %q{Persist credential for google-drive-ruby.}
  spec.description   = %q{Persist credential for google-drive-ruby.}
  spec.homepage      = 'https://github.com/winebarrel/google_drive-persistent_session'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'google_drive', '>= 1.0.0'
  spec.add_dependency 'highline'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
