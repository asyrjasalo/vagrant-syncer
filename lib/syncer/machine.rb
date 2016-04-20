require 'vagrant/action/builtin/mixin_synced_folders'

require_relative 'syncers/rsync'

module Vagrant
  module Syncer
    class Machine

      include Vagrant::Action::Builtin::MixinSyncedFolders

      def initialize(machine, polling=false)
        @paths = []
        @syncers = []
        @excludes = []
        @logger = machine.ui

        @listener_verbose = machine.config.syncer.show_events
        @listener_interval = machine.config.syncer.interval

        listener_settings = {
          latency: @listener_interval,
          wait_for_delay: @listener_interval / 2
        }

        if polling
          require_relative 'listeners/listen'
          @listener_class = Vagrant::Syncer::Listeners::Listen
          listener_settings[:force_polling] = polling
        elsif machine.config.syncer.force_listen_gem
          require_relative 'listeners/listen'
          @listener_class = Vagrant::Syncer::Listeners::Listen
        else
          case Vagrant::Util::Platform.platform
          when /darwin/
            require_relative 'listeners/fsevents'
            @listener_class = Vagrant::Syncer::Listeners::FSEvents
          when /linux/
            require_relative 'listeners/inotify'
            @listener_class = Vagrant::Syncer::Listeners::INotify
          else
            require_relative 'listeners/listen'
            @listener_class = Vagrant::Syncer::Listeners::Listen
          end
        end

        @listener_name = @listener_class.to_s.gsub(/^.*::/, '')

        rsync_synced_folders = synced_folders(machine)[:rsync]

        if rsync_synced_folders
          rsync_synced_folders.each do |id, folder_opts|
            @paths << File.expand_path(folder_opts[:hostpath], machine.env.root_path)
            @excludes << folder_opts[:rsync__excludes]  if folder_opts[:rsync__excludes]
            @syncers << Syncers::Rsync.new(folder_opts, machine)
          end
        end

        @listener = @listener_class.new(
          @paths,
          @excludes,
          listener_settings,
          change_callback
        )
      end

      def full_sync
        @syncers.each do |syncer|
          @logger.info(I18n.t('syncer.states.initial', {
            host_path: syncer.host_path,
            guest_path: syncer.guest_path
          }))
          syncer.sync([syncer.host_path], initial=true)
        end
      end

      def listen
        text = @listener_polling ? 'syncer.states.polling' : 'syncer.states.watching'
        @paths.each do |path|
          @logger.info(I18n.t(text, {
            host_path: path,
            listener: @listener_name,
            interval: @listener_interval
          }))
        end
        @listener.run
      end

      private

      def change_callback
        Proc.new do |changed|
          if @listener_verbose
            @logger.info(@listener_name + ": " + changed.join(', '))
          end
          @syncers.each do |syncer|
            syncer.sync(changed)
          end
        end
      end

    end
  end
end
