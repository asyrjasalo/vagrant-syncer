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
          return  unless argv

          # Go through each machine and perform full sync.
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

            next  unless machine.communicate.ready?
            next  unless synced_folders(machine)[:rsync]

            if machine.ssh_info
              Machine.new(machine).full_sync
            end
          end

          return 0
        end
      end
    end
  end
end
