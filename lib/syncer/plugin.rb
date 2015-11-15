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

    end
  end
end
