require "thin"

class Writing
  class Server
    # @return [Hash] The options for the parent instance.
    attr_reader :options

    # @return [String] The root path for the parent instance.
    attr_reader :root

    # Initializes with the provided instance.
    #
    # @param [Writing] instance The parent instance.
    def initialize(instance)
      @root    = instance.root
      @options = instance.options
    end

    # Starts the web server in a new thread.
    def start
      root    = self.root
      options = self.options

      Thin::Logging.silent = !options[:verbose]

      server = Thin::Server.new("0.0.0.0", options[:port]) do
        use Rack::CommonLogger if options[:verbose]
        use Rack::Deflater
        use Rack::Static, :root => root, :index => "index.html"
        run lambda {}
      end

      Thread.new do
        server.start
      end.join
    end
  end
end
