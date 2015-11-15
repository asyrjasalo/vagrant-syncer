require 'vagrant/action/builtin/mixin_synced_folders'

module Vagrant
  module Syncer
    class Machine

      include Vagrant::Action::Builtin::MixinSyncedFolders

      def initialize(machine)
        @paths = []

        synced_folders = synced_folders(machine)[:rsync]
        return  unless synced_folders

        synced_folders.each do |id, folder_opts|
          @paths << Path.new(folder_opts, machine)
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