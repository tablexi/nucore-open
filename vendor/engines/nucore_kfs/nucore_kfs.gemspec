$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "nucore_kfs/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "nucore_kfs"
  s.version     = NucoreKfs::VERSION
  s.authors     = ["UConn"]
  s.email       = []
  s.homepage    = "https://github.com/SquaredLabs/nucore-uconn"
  s.summary     = "Integrates UConn KFS with NUcore"
  s.description = "Integrates UConn KFS with NUcore"
  s.license     = "MIT"
  # providing all of this information is necessary, because of gem validation

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.10"
end
