module Vagrant
  module Syncer
    class Plugin < Vagrant.plugin(2)

      name "Syncer"

      description <<-DESC
      Watches for changed files on the host and synchronizes them to the machine.
      DESC

      config "syncer" do
        require 'syncer/config'
        Vagrant::Syncer::Config
      end

      command "syncer" do
        require 'syncer/commands/syncer'
        Vagrant::Syncer::Commands::Syncer
      end

      # TODO: generate these three using Ruby's metaprogramming
      action_hook "start-syncer", :machine_action_up do |hook|
        hook.append Vagrant::Syncer::Actions::StartSyncer
      end

      action_hook "start-syncer", :machine_action_reload do |hook|
        hook.append Vagrant::Syncer::Actions::StartSyncer
      end

      action_hook "start-syncer", :machine_action_resume do |hook|
        hook.append Vagrant::Syncer::Actions::StartSyncer
      end

    end
  end
end
