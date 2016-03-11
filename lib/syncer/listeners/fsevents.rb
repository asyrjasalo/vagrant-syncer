require "rb-fsevent"

module Vagrant
  module Syncer
    module Listeners
      class FSEvents

        def initialize(absolute_path, excludes, settings, callback)
          @absolute_path = absolute_path
          @settings = settings.merge!(no_defer: false)
          @callback = callback
          # rb-fsevent does not support excludes.
        end

        def run
          changes = Queue.new
          fsevent = FSEvent.new
          fsevent.watch @absolute_path, @settings do |paths|
            paths.each { |path| changes << path }
          end
          Thread.new { fsevent.run }

          loop do
            directories = Set.new
            change = changes.pop
            directories << change  unless change.nil?
            @callback.call(directories.to_a)  unless directories.empty?
          end
        end

      end
    end
  end
end
