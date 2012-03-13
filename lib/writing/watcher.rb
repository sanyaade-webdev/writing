require "directory_watcher"

class Writing
  class Watcher
    # @return [Writing] The parent +Writing+ instance.
    attr_reader :instance

    # @return [Hash] The options for the parent instance.
    attr_reader :options

    # @return [String] The root path for the parent instance.
    attr_reader :root

    # Initializes with the provided instance.
    #
    # @param [Writing] instance The parent instance.
    def initialize(instance)
      @root     = instance.root
      @options  = instance.options
      @instance = instance
    end

    # Log file changes with a timestamp.
    #
    # If verbose, a new line is immediately printed, otherwise "Done."
    # and a new line are printed after the yielded block returns.
    #
    # @param [Array] events The file change events.
    def log(events, &block)
      print "[#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}] "
      print "#{events.size} files changed, regenerating..."
      print "\n" if verbose?

      yield if block_given?

      print " Done.\n" unless verbose?
    end

    # Start the directory watcher.
    #
    # If a server has not been started, an infinite loop with a one
    # second sleep is started.
    def start
      watcher = DirectoryWatcher.new(root, :interval => 1, :glob => ["**/*", "**/**/*"])
      watcher.add_observer(method(:update), :call)
      watcher.start

      loop do
        sleep(1000)
      end unless options["server"]
    end

    # Updates the parent instance, unless the only event
    # is for the output file.
    #
    # @param [...] events The file change events.
    def update(*events)
      log(events) do
        @instance.update
      end unless only_output_file?(events)
    end

    # Returns whether or not verbose output is enabled.
    #
    # @return [Boolean] Whether or not verbose output is enabled.
    def verbose?
      options["verbose"]
    end

    private

    def only_output_file?(events)
      events.size == 1 && events[0].path =~ /\/index.html$/
    end
  end
end
