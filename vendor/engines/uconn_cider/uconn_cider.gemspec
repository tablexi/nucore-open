$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "uconn_cider/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "uconn_cider"
  s.version     = UconnCider::VERSION
  s.authors     = ["Joseph O'Shea"]
  s.email       = ["joseph.oshea@uconn.edu"]
  s.homepage    = "https://cider.uconn.edu"
  s.summary     = "Customizations for UConn's CIDER"
  s.description = "Customizations for UConn's CIDER"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 5.2.3"

  s.add_development_dependency "sqlite3"
end
