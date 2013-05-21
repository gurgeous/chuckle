$LOAD_PATH << File.expand_path("../lib", __FILE__)

require "chuckle/version"

Gem::Specification.new do |s|
  s.name        = "chuckle"
  s.version     = Chuckle::VERSION
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = ">= 1.9.0"
  s.authors     = ["Adam Doppelt"]
  s.email       = ["amd@gurge.com"]
  s.homepage    = "http://github.com/gurgeous/chuckle"
  s.summary     = "Chuckle - an http client that caches on disk."
  s.description = "An http client that caches on disk."

  s.rubyforge_project = "chuckle"

  s.add_runtime_dependency "trollop"

  s.add_development_dependency "awesome_print"
  s.add_development_dependency "json"
  s.add_development_dependency "minitest", "~> 5.0"
  s.add_development_dependency "rake"
  s.add_development_dependency "rdoc"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |i| File.basename(i) }
  s.require_paths = ["lib"]
end
