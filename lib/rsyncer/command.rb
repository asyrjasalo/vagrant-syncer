module Vagrant
  module Rsyncer
    class Command < Vagrant.plugin(2, :command)

      def self.synopsis
        "start the rsyncer"
      end

      def execute
        with_target_vms do |machine|
          @env.ui.info I18n.t('rsyncer.info.started')
        end

        0
      end

    end
  end
end
