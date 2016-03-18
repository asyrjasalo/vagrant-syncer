require "rb-inotify"

module Vagrant
  module Syncer
    module Listeners
      class INotify

        def initialize(paths, excludes, settings, callback)
          @paths = paths
          @settings = settings
          @callback = callback
          # rb-inotify does not support excludes.
        end

        def run
          notifier = ::INotify::Notifier.new

          @paths.each do |path|
            notifier.watch(path, :modify, :create, :delete, :recursive) {}
          end

          loop do
            directories = Set.new
            notifier.read_events.each { |e| directories << e.absolute_name }
            @callback.call(directories.to_a)  unless directories.empty?
          end
        end
      end
    end
  end
end
