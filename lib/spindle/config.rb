module Vagrant
  module Spindle
    class Config < Vagrant.plugin(2, :config)

      attr_accessor :config, :settings

      def initialize
        @config = nil
      end

      def finalize!
        unless @config
          raise Vagrant::Errors::VagrantError.new,
            I18n.t('spindle.config.undefined')
        end

        begin
          config_content = File.read(@config)
          @settings = JSON.parse(config_content, symbolize_names: true)
        rescue Errno::ENOENT, JSON::ParserError => error
          raise Vagrant::Errors::VagrantError.new, error
        end
      end

    end
  end
end
