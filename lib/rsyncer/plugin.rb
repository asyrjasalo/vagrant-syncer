module Vagrant
  module Rsyncer
    class Plugin < Vagrant.plugin(2)

      name "Rsyncer"
      description <<-DESC
      Monitors host filesystem events and continuously rsyncs files to the guest.
      DESC

      config "rsyncer" do
        require 'rsyncer/config'
        Vagrant::Rsyncer::Config
      end

      command "rsyncer" do
        Vagrant::Rsyncer::Command
      end

      action_hook :initial_rsync, :machine_action_up do |hook|
        hook.append Vagrant::Rsyncer::Actions::Up
      end

      action_hook :initial_rsync, :machine_action_reload do |hook|
        hook.append Vagrant::Rsyncer::Actions::Reload
      end

      action_hook :initial_rsync, :machine_action_provision do |hook|
        hook.append Vagrant::Rsyncer::Actions::Provision
      end

      action_hook :initial_rsync, :machine_action_suspend do |hook|
        hook.append Vagrant::Rsyncer::Actions::Suspend
      end

      action_hook :initial_rsync, :machine_action_resume do |hook|
        hook.append Vagrant::Rsyncer::Actions::Resume
      end

      action_hook :initial_rsync, :machine_action_halt do |hook|
        hook.append Vagrant::Rsyncer::Actions::Halt
      end

      action_hook :initial_rsync, :machine_action_destroy do |hook|
        hook.append Vagrant::Rsyncer::Actions::Destroy
      end

    end
  end
end
