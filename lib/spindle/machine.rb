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
        @paths.select(&:do_initial).each do |path|
          @logger.info(I18n.t('spindle.states.initial'))
          path.initial
        end
      end

      def listen
        @paths.select(&:do_continuous).each do |path|
          @logger.info(I18n.t('spindle.states.watching', {
            path: path.absolute_path,
            adapter: path.listener_class,
            interval: path.listener_interval
          }))
          path.listen
        end
      end

    end
  end
end