require "closure-compiler"
require "ejs"
require "pathname"
require "sass"
require "sprockets"
require "yui/compressor"

# The base Writing class.
class Writing
  autoload :Server,  "writing/server"
  autoload :Watcher, "writing/watcher"

  # Writing version.
  VERSION = "0.1.0"

  # @return [Hash] The options for the current instance.
  attr_reader :options

  # Initializes with the provided options.
  #
  # @param [Hash] options The options for the instance.
  # @option options [Boolean] :auto    Enable auto-regenerate.
  # @option options [String]  :root    A custom root directory. (Defaults to +Dir.pwd+.)
  # @option options [Integer] :port    A port for the server to listen on.
  # @option options [Boolean] :verbose Enable verbose output.
  def initialize(options = {})
    @options = options
  end

  # Returns a +Pathname+ for either the specified root, or the current
  # working directory.
  #
  # @return [Pathname]
  def root
    Pathname.new(options[:root] || Dir.pwd)
  end

  # Returns the compiled source for the asset at the provided +path+.
  #
  # @param [String] path The path of the asset.
  # @return [String] Compiled source for the asset.
  def source_for(path)
    sprockets.find_asset(path).source
  end

  # Initializes a +Sprockets::Environment+ for the root directory,
  # with CSS and JS compressors, and appends the necessary paths.
  #
  # @return [Sprockets::Environment] The new environment.
  def sprockets
    unless @sprockets
      @sprockets = Sprockets::Environment.new(root)
      @sprockets.js_compressor =  Closure::Compiler.new
      @sprockets.css_compressor = YUI::CssCompressor.new
      @sprockets.append_path(root.join("public"))
      @sprockets.append_path(root.join("public", "js"))
      @sprockets.append_path(root.join("public", "js", "vendor"))
    end

    @sprockets
  end

  # Start the watcher and server, when enabled.
  def start
    Watcher.new(self).start if options[:auto]
    Server.new(self).start  if options[:port]
  end

  # Compiles the application CSS and JS and renders the +index.html.erb+
  # to +index.html+.
  def update
    css        = source_for("css/application.css")
    javascript = source_for("js/application.js")
    template   = ERB.new(File.read(root.join("index.html.erb")))
    template   = template.result(binding)

    File.write(root.join("index.html"), template)
  end
end
