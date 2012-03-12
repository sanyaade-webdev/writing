require File.expand_path("../../lib/writing", __FILE__)
require "bundler/setup"

require "bourne"

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each do |file|
  require file
end

RSpec.configure do |config|
  config.mock_with :mocha
end
