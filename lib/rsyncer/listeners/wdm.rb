require "wdm"

module Vagrant
  module Rsyncer
    module Listeners
      class Wdm
        def initialize(paths, ignores, latency, logger, callback)
          @paths = paths
          @ignores = ignores
          @latency = latency
          @logger = logger
          @callback = callback
        end

        def run
          @ui.info("Running on Windows, listening via WDM.")

          changes = Queue.new
          monitor = WDM::Monitor.new

          @paths.keys.each do |path|
            monitor.watch_recursively(path.dup) { |change| changes << change }
          end
          Thread.new { monitor.run! }

          loop do
            changed_paths = Set.new
            begin
              loop do
                change = Timeout::timeout(@latency) {
                  changes.pop
                }
                changed_paths << change.path
              end
            rescue Timeout::Error
              @callback.call(@paths, @ignores, changed_paths) unless changed_paths.empty?
            end
          end
        end
      end
    end
  end
end
