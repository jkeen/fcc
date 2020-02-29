lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "version"

Gem::Specification.new do |s|
  s.name = %q{fcc}
  s.version = FCC::VERSION

  s.authors = ["Jeff Keen"]
  s.date = %q{2011-01-30}
  s.description = %q{}
  s.email = %q{jeff@keen.me}
  s.homepage      = "http://github.com/jkeen/fcc"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rvmrc",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/am.rb",
    "lib/fcc.rb",
    "lib/fm.rb",
    "test/helper.rb",
    "test/test_fcc.rb"
  ]
  s.homepage = %q{http://github.com/jkeen/fcc}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.4.1}
  s.summary = %q{Searches the FCC's FM and AM databases}
  s.test_files = [
    "test/helper.rb",
    "test/test_fcc.rb"
  ]

  s.add_dependency(%q<nokogiri>, [">= 0"])
  s.add_development_dependency "bundler", "~> 1.16"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "shoulda", ">= 0"
end
