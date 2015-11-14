require 'vagrant/action/builtin/mixin_synced_folders'


module Vagrant
  module Syncer
    class Machine

      include Vagrant::Action::Builtin::MixinSyncedFolders

      def initialize(machine)
        @logger = machine.ui
        @paths = []

        synced_folders(machine)[:rsync].each do |id, folder_opts|
          @paths << Path.new(folder_opts, machine)
        end
      end

      def full
        @paths.select(&:do_initial).each do |path|
          @logger.info(I18n.t('syncer.states.initial'))
          path.initial
        end
      end

      def listen
        @paths.select(&:do_continuous).each do |path|
          @logger.info(I18n.t('syncer.states.watching', {
            path: path.absolute_path,
            listener: path.listener_name,
            interval: path.listener_interval
          }))
          path.listen
        end
      end

    end
  end
end