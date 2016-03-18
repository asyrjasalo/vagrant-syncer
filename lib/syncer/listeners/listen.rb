require 'listen'

module Vagrant
  module Syncer
    module Listeners
      class Listen

        def self.excludes_to_listen(exclude)
          exclude = exclude.gsub('**', '"GLOBAL"')
          exclude = exclude.gsub('*', '"PATH"')

          if exclude.start_with?('/')
            pattern = "^#{Regexp.escape(exclude[1..-1])}"
          else
            pattern = Regexp.escape(exclude)
          end

          pattern = pattern.gsub('"PATH"', "[^/]*")
          pattern = pattern.gsub('"GLOBAL"', ".*")

          Regexp.new(pattern)
        end

        def initialize(paths, excludes, settings, callback)
          @paths = paths
          @settings = settings
          @callback = callback

          if excludes
            @settings[:ignore!] = []
            excludes.each do |pattern|
              @settings[:ignore!] << self.class.excludes_to_listen(pattern.to_s)
            end
          end
        end

        def run
          listener = ::Listen.to(*@paths, @settings) do |mod, add, rem|
            @callback.call(mod + add + rem)
          end

          listener.start
          sleep
        end
      end
    end
  end
end
