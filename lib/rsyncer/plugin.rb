module VagrantPlugins
  module Rsyncer
    class Plugin < Vagrant.plugin(2)

      name "Rsyncer"
      description <<-DESC
      Continuously rsyncs the changed files to the guest.
      DESC

      def self.source_root
        File.expand_path("../../../", __FILE__)
      end

      I18n.load_path << File.expand_path("locales/en.yml", self.source_root)
      I18n.reload!

      config "rsyncer" do
        require_relative "config"
        Config
      end

      command "rsyncer" do
        require_relative "command"
        Command
      end

      action_hook "initial-rsync" do |hook|
        require_relative "initial_rsync"
        hook.after Vagrant::Action::Builtin::SyncedFolders, InitialRsync
      end

    end
  end
end
