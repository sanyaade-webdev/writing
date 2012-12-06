Gem::Specification.new do |s|
  s.name        = "writing"
  s.version     = "0.1.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Tristan Dunn"]
  s.email       = "hello@tristandunn.com"
  s.homepage    = "https://github.com/tristandunn/writing"
  s.summary     = "A single-page publishing tool written in JavaScript."
  s.description = "A single-page publishing tool written in JavaScript."

  s.files        = Dir["lib/**/*"].to_a
  s.test_files   = Dir["spec/**/*"].to_a
  s.require_path = "lib"

  s.executables << "writing"

  s.add_dependency "closure-compiler",  "1.1.7"
  s.add_dependency "directory_watcher", "1.4.1"
  s.add_dependency "ejs",               "1.1.1"
  s.add_dependency "sass",              "3.2.3"
  s.add_dependency "sprockets",         "2.8.1"
  s.add_dependency "thin",              "1.5.0"
  s.add_dependency "thor",              "0.16.0"
  s.add_dependency "yui-compressor",    "0.9.6"

  s.add_development_dependency "bourne",    "1.3.0"
  s.add_development_dependency "rake",      "10.0.2"
  s.add_development_dependency "redcarpet", "2.2.2"
  s.add_development_dependency "rspec",     "2.12.0"
  s.add_development_dependency "yard",      "0.8.3"
end
