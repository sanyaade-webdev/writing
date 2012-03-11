require "rubygems"
require "closure-compiler"
require "sinatra"
require "sprockets"
require "yui/compressor"

class Application < Sinatra::Base
  set :root,        File.dirname(__FILE__)
  set :sprockets,   Sprockets::Environment.new(root)

  configure do
    sprockets.js_compressor  = Closure::Compiler.new
    sprockets.css_compressor = YUI::CssCompressor.new

    sprockets.append_path(File.join(root, "_public"))
    sprockets.append_path(File.join(root, "_public/js"))
    sprockets.append_path(File.join(root, "_public/js/vendor"))
  end

  get "/" do
    @css        = settings.sprockets.find_asset("css/application.css").source
    @javascript = settings.sprockets.find_asset("js/application.js").source

    erb File.read("index.html")
  end

  get "/posts/*" do |name|
    File.read("_posts/#{name}")
  end
end

map "/" do
  use Rack::Deflater
  run Application
end
