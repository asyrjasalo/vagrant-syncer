require "rb-fsevent"

module Vagrant
  module Rsyncer
    module Listeners
      class FSEvents
        def initialize(paths, ignores, latency, ui, callback)
          @paths = paths
          @ignores = ignores
          @latency = latency
          @options = {
            :latency => latency,
            :no_defer => false,
          }
          @ui = ui
          @callback = callback
        end

        def run
          @ui.info("Running on OS X, listening via FSEvents.")

          changes = Queue.new
          fsevent = FSEvent.new

          fsevent.watch @paths, @options do |paths|
            paths.each { |file| changes << file }
          end
          Thread.new { fsevent.run }

          loop do
            changed_paths = Set.new
            begin
              loop do
                change = Timeout::timeout(@latency) {
                  changes.pop
                }
                changed_paths << change unless change.nil?
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
