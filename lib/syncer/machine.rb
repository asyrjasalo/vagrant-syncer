require 'vagrant/action/builtin/mixin_synced_folders'

module Vagrant
  module Syncer
    class Machine

      include Vagrant::Action::Builtin::MixinSyncedFolders

      def initialize(machine, polling=false)
        @paths = []

        synced_folders(machine)[:rsync].each do |id, folder_opts|
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
