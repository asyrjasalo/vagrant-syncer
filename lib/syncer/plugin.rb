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

      command "syncer" do
        require 'syncer/commands/syncer'
        Vagrant::Syncer::Commands::Syncer
      end

      ["machine_action_up", "machine_action_reload", "machine_action_resume"].each do |action|
        action_hook "start-syncer", action do |hook|
          hook.append Vagrant::Syncer::Actions::StartSyncer
        end
      end

    end
  end
end
