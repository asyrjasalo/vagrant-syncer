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
        require 'spindle/commands/spindle'
        Vagrant::Spindle::Commands::Spindle
      end

      command "spin" do
        require 'spindle/commands/spin'
        Vagrant::Spindle::Commands::Spin
      end

      action_hook :initial, :machine_action_up do |hook|
        hook.append Vagrant::Spindle::Actions::Up
      end

      action_hook :initial, :machine_action_reload do |hook|
        hook.append Vagrant::Spindle::Actions::Reload
      end

      action_hook :initial, :machine_action_resume do |hook|
        hook.append Vagrant::Spindle::Actions::Resume
      end

    end
  end
end
