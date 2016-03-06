require 'vagrant/action/builtin/mixin_synced_folders'

module Vagrant
  module Syncer
    class Machine

      include Vagrant::Action::Builtin::MixinSyncedFolders

      def initialize(machine, polling=false)
        @paths = []

        cached = synced_folders(machine, cached: true)
        fresh  = synced_folders(machine)
        diff   = synced_folders_diff(cached, fresh)
        if !diff[:added].empty?
          machine.ui.warn(I18n.t("vagrant.rsync_auto_new_folders"))
        end

        folders = cached[:rsync]
        folders.each do |id, folder_opts|
          @paths << Path.new(folder_opts, machine, polling)
        end
      end

      def full_sync
        @paths.each(&:initial_sync)
      end

      def listen
        @paths.each(&:listen)
      end

    end
  end
end
