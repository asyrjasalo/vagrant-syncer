require "log4r"
require 'optparse'

require "vagrant/action/builtin/mixin_synced_folders"
require "vagrant/util/platform"


# This is to avoid a bug in nio 1.0.0. Remove around nio 1.0.1.
ENV["NIO4R_PURE"] = "1"  if Vagrant::Util::Platform.windows?

module Vagrant
  module Syncer
    module Command
      class RsyncAuto < Vagrant.plugin("2", :command)
        include Vagrant::Action::Builtin::MixinSyncedFolders

        def self.synopsis
          "syncs rsync synced folders automatically when files change"
        end

        def execute
          @logger = Log4r::Logger.new("vagrant::commands::rsync-auto")

          options = {}
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant rsync-auto [vm-name]"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("--[no-]poll", "Force polling filesystem (slow)") do |poll|
              options[:poll] = poll
            end
          end

          # Parse the options and return if we don't have any target.
          argv = parse_options(opts)
          return if !argv

          listener_threads = []

          # Build up the paths that we need to listen to.
          with_target_vms(argv) do |machine|
            if machine.provider.capability?(:proxy_machine)
              proxy = machine.provider.capability(:proxy_machine)
              if proxy
                machine.ui.warn(I18n.t(
                  "vagrant.rsync_proxy_machine",
                  name: machine.name.to_s,
                  provider: machine.provider_name.to_s
                ))
                machine = proxy
              end
            end

            next  unless synced_folders(machine)[:rsync]

            machine = Machine.new(machine, options[:poll])
            machine.full_sync
            listener_threads << Thread.new { machine.listen }
          end
          listener_threads.each { |t| t.join }
        end
      end
    end
  end
end
