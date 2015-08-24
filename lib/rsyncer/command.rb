module VagrantPlugins
  module Rsyncer
    class Command < Vagrant.plugin(2, :command)

      def self.synopsis
        "start rsyncer"
      end

      def execute
        @env.ui.info I18n.t('rsyncer.info.started')
      end

    end
  end
end
