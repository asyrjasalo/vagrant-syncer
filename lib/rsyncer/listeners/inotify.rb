require "rb-inotify"

module Vagrant
  module Rsyncer
    module Listeners
      class Inotify
        def initialize(paths, ignores, latency, ui, callback)
          @paths = paths
          @ignores = ignores
          @latency = latency
          @logger = logger
          @callback = callback
        end

        def run
          @ui.info("Running on GNU/Linux, listening via inotify.")

          notifier = INotify::Notifier.new

          @paths.keys.each do |path|
            notifier.watch(path, :modify, :create, :delete, :move, :recursive) {}
          end
          Thread.new { notifier.run }

          loop do
            begin
              changed_paths = Set.new
              loop do
                events = []
                events = Timeout::timeout(@latency) {
                  notifier.read_events
                }
                events.each { |e| changed_paths << e.absolute_name }
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
