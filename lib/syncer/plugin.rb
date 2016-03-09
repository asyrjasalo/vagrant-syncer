module Vagrant
  module Syncer
    class Plugin < Vagrant.plugin(2)

      name "Syncer"

      description <<-DESC
      Watches for changed files on the host and rsyncs them to the machine.
      DESC

      config "syncer" do
        require 'syncer/config'
        Vagrant::Syncer::Config
      end

      command("rsync", primary: false) do
        require_relative "command/rsync"
        Vagrant::Syncer::Command::Rsync
      end

      command("rsync-auto", primary: false) do
        require_relative "command/rsync_auto"
        Vagrant::Syncer::Command::RsyncAuto
      end

      command("syncer", primary: false) do
        require_relative "command/rsync_auto"
        Vagrant::Syncer::Command::RsyncAuto
      end

      synced_folder("rsync", 5) do
        require_relative "synced_folder"
        SyncedFolder
      end

      ["machine_action_up", "machine_action_reload", "machine_action_resume"].each do |action|
        action_hook "start-syncer", action do |hook|
          hook.append Vagrant::Syncer::Actions::StartSyncer
        end
      end

    end
  end
end
