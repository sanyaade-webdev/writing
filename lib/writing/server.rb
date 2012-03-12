require "thin"

class Writing
  class Server
    def initialize(instance)
      @root    = instance.root
      @options = instance.options
    end

    def start
      root    = @root
      options = @options

      Thread.new do
        Thin::Logging.silent = !options[:verbose]
        Thin::Server.start("0.0.0.0", options[:port]) do
          use Rack::CommonLogger if options[:verbose]
          use Rack::Deflater
          use Rack::Static, :root => root, :index => "index.html"
          run lambda {}
        end
      end.join
    end
  end
end
