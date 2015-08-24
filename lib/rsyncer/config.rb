module VagrantPlugins
  module Rsyncer
    class Config < Vagrant.plugin(2, :config)

      attr_accessor :settings

      def initialize
        @settings = UNSET_VALUE
      end

      def finalize!
        # TODO: set defaults
      end

      def validate(machine)
        errors = _detected_errors

        # TODO: do validations for machine.config.rsyncer.settings
        # and append to errors (an array)

        { "rsyncer" => errors }
      end

    end
  end
end
