module Vagrant
  module Spindle
    class Plugin < Vagrant.plugin(2)

      name "Spindle"
      description <<-DESC
      Listens host filesystem events and syncs changes to the guest.
      DESC

      config "spindle" do
        require 'spindle/config'
        Vagrant::Spindle::Config
      end

      command "spindle" do
        Vagrant::Spindle::Command
      end

      action_hook :initial, :machine_action_up do |hook|
        hook.append Vagrant::Spindle::Actions::Up
      end

      action_hook :initial, :machine_action_reload do |hook|
        hook.append Vagrant::Spindle::Actions::Reload
      end

      action_hook :initial, :machine_action_provision do |hook|
        hook.append Vagrant::Spindle::Actions::Provision
      end

      action_hook :initial, :machine_action_suspend do |hook|
        hook.append Vagrant::Spindle::Actions::Suspend
      end

      action_hook :initial, :machine_action_resume do |hook|
        hook.append Vagrant::Spindle::Actions::Resume
      end

      action_hook :initial, :machine_action_halt do |hook|
        hook.append Vagrant::Spindle::Actions::Halt
      end

      action_hook :initial, :machine_action_destroy do |hook|
        hook.append Vagrant::Spindle::Actions::Destroy
      end

    end
  end
end
