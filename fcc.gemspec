lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "version"

Gem::Specification.new do |spec|
  spec.name = %q{fcc}
  spec.version = FCC::VERSION
  spec.authors = ["Jeff Keen"]
  spec.description = %q{}
  spec.email = %q{jeff@keen.me}
  spec.homepage      = "http://github.com/jkeen/fcc"
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.homepage = %q{http://github.com/jkeen/fcc}
  spec.licenses = ["MIT"]
  spec.required_ruby_version = ">= 2.7"
  spec.summary = %q{Searches the FCC's FM, AM, and TV databases}
  spec.add_dependency "activesupport", ">= 6.1"
  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "csv"
  spec.add_dependency "lightly", "~> 0.4.0"
  spec.add_dependency "rubyzip", "~> 2.3.2"
  spec.add_dependency "logger"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 12.3.3"
  spec.add_development_dependency 'rspec', '~> 3.9.0'
end
