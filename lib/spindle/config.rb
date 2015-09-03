module Vagrant
  module Spindle
    class Config < Vagrant.plugin(2, :config)

      attr_accessor :settings

      def initialize
        @settings = {}
      end

    end
  end
end
