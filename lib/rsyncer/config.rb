module VagrantPlugins
  module Rsyncer
    class Config < Vagrant.plugin(2, :config)

      attr_accessor :path

      def initialize
        @path = UNSET_VALUE
      end

      def finalize!
      end

      def validate(machine)
        begin
          config_file = File.read(machine.config.rsyncer.path)
        rescue Errno::ENOENT
          raise Errors::ConfigNotFound
        end
      end

    end
  end
end
