require "rb-inotify"

module Vagrant
  module Syncer
    module Listeners
      class INotify

        def initialize(absolute_path, excludes, settings, callback)
          @absolute_path = absolute_path
          @settings = settings
          @callback = callback
          # rb-inotify does not support excludes
        end

        def run
          notifier = INotify::Notifier.new
          notifier.watch(@absolute_path, :modify, :create, :delete, :recursive) {}

          loop do
            directories = Set.new
            begin
              loop do
                events = []
                events = Timeout::timeout(@settings[:latency]) {
                  notifier.read_events
                }
                events.each { |e| directories << e.absolute_name }
              end
            rescue Timeout::Error
            end

            @callback.call(directories)  unless directories.empty?
          end
        end
      end
    end
  end
end
