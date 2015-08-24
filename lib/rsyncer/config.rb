module VagrantPlugins
  module Rsyncer
    class Config < Vagrant.plugin(2, :config)

      attr_accessor :path

      def initialize
        @path = UNSET_VALUE
      end

      def finalize!
        # set defaults
      end

      def validate(machine)
        errors = _detected_errors

        config_path = machine.config.rsyncer.path
        if config_path == UNSET_VALUE
          errors << "Config file not given."
        else
          begin
            config_file = File.read(config_path)
            config_json = JSON.parse(config_file)

            puts config_json
          rescue Errno::ENOENT
            errors << "Config file '#{config_path}' not found."
          rescue JSON::ParserError
            errors << "Config file not valid JSON."
          end
        end

        { "rsyncer" => errors }
      end

    end
  end
end
