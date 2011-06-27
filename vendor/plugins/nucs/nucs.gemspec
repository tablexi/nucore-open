Gem::Specification.new do |s|
  s.version = '0.0.1'
  s.name = "nucs"
  s.files = Dir["lib/**/*", "app/**/*", "config/**/*"]
  s.summary = "Northwestern University chartstring validator"
  s.description = "Implenents Northwestern's v9 chartstring validation rules'"
  s.email = "nucs@tablexi.com"
  s.homepage = "http://tablexi.com"
  s.authors = ["Chris Stump"]
  s.test_files = []
  s.require_paths = [".", "lib"]
  s.has_rdoc = 'false'
end