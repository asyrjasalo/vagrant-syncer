require 'optparse'

require "vagrant/action/builtin/mixin_synced_folders"


module Vagrant
  module Syncer
    module Command
      class Rsync < Vagrant.plugin(2, :command)

        include Vagrant::Action::Builtin::MixinSyncedFolders

        def self.synopsis
          "syncs rsync synced folders to remote machine"
        end

        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant rsync [vm-name]"
            o.separator ""
            o.separator "This command forces any synced folders with type 'rsync' to sync."
            o.separator "RSync is not an automatic sync so a manual command is used."
            o.separator ""
            o.separator "Options:"
            o.separator ""
          end

          # Parse the options and return if we don't have any target.
          argv = parse_options(opts)
          return if !argv

          # Go through each machine and perform full sync.
          error = false
          with_target_vms(argv) do |machine|
            if machine.provider.capability?(:proxy_machine)
              proxy = machine.provider.capability(:proxy_machine)
              if proxy
                machine.ui.warn(I18n.t(
                  "vagrant.rsync_proxy_machine",
                  name: machine.name.to_s,
                  provider: machine.provider_name.to_s))

                machine = proxy
              end
            end

            next if synced_folders(machine)[:rsync].empty?

            if !machine.communicate.ready?
              machine.ui.error(I18n.t("vagrant.rsync_communicator_not_ready"))
              error = true
              next
            end

            Machine.new(machine).full_sync
          end

          return error ? 1 : 0
        end
      end
    end
  end
end
