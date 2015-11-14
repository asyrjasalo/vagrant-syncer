module Vagrant
  module Syncer
    class Plugin < Vagrant.plugin(2)

      name "Syncer"
      description <<-DESC
      Watches for changed files on the host and synchronizes them to the guest.
      DESC

      config "syncer" do
        require 'syncer/config'
        Vagrant::Syncer::Config
      end

      command "syncer" do
        require 'syncer/commands/syncer'
        Vagrant::Syncer::Commands::Syncer
      end

      action_hook :initial, :machine_action_up do |hook|
        hook.append Vagrant::Syncer::Actions::Up
      end

      action_hook :initial, :machine_action_reload do |hook|
        hook.append Vagrant::Syncer::Actions::Reload
      end

      action_hook :initial, :machine_action_resume do |hook|
        hook.append Vagrant::Syncer::Actions::Resume
      end

    end
  end
end
