require "rb-fsevent"

module Vagrant
  module Spindle
    module Listeners
      class FSEvents

        def initialize(absolute_path, excludes, settings, callback)
          @absolute_path = absolute_path
          @settings = settings
          @callback = callback
          # rb-fsevent does not support excludes
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
            begin
              loop do
                change = Timeout::timeout(@settings[:latency]) { changes.pop }
                directories << change  unless change.nil?
              end
            rescue Timeout::Error, ThreadError
            end

            @callback.call(directories)  unless directories.empty?
          end
        end

      end
    end
  end
end
