module Vagrant
  module Spindle
    class Machine

      def initialize(machine)
        @logger = machine.ui
        @paths = []
        machine.config.spindle.settings[:paths].each do |path|
          @paths << Path.new(path, machine)
        end
      end

      def full
        @paths.select(&:initial_enabled).each do |path|
          @logger.info(I18n.t('spindle.states.initial'))
          path.initial
        end
      end

      def listen
        @paths.select(&:listen_enabled).each do |path|
          @logger.info(I18n.t('spindle.states.watching', {
            adapter: Listen::Adapter.select,
            path: path.absolute_path
          }))
          path.listen
        end
      end

    end
  end
end