require "rb-inotify"

module Vagrant
  module Syncer
    module Listeners
      class INotify

        def initialize(absolute_path, excludes, settings, callback)
          @absolute_path = absolute_path
          @settings = settings
          @callback = callback
          # rb-inotify does not support excludes.
        end

        def run
          notifier = ::INotify::Notifier.new
          notifier.watch(@absolute_path, :modify, :create, :delete, :recursive) {}

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
