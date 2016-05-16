require 'vagrant/action/builtin/mixin_synced_folders'

require_relative 'syncers/rsync'

module Vagrant
  module Syncer
    class Machine

      include Vagrant::Action::Builtin::MixinSyncedFolders

      def initialize(machine)
        @machine = machine
        @logger = @machine.ui

        @rsync_synced_folders = synced_folders(@machine)[:rsync]

        @syncers = []
        @rsync_synced_folders.each do |id, folder_opts|
          @syncers << Syncers::Rsync.new(folder_opts, @machine)
        end
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

      def listen(polling=false)
        listener_excludes = []
        listener_interval = @machine.config.syncer.interval
        listener_verbose = @machine.config.syncer.show_events
        listener_force_listen = @machine.config.syncer.force_listen_gem
        listener_settings = {
          latency: listener_interval,
          wait_for_delay: listener_interval / 2
        }

        if polling
          require_relative 'listeners/listen'
          listener_class = Vagrant::Syncer::Listeners::Listen
          listener_settings[:force_polling] = polling
        elsif listener_force_listen
          require_relative 'listeners/listen'
          listener_class = Vagrant::Syncer::Listeners::Listen
        else
          case Vagrant::Util::Platform.platform
          when /darwin/
            require_relative 'listeners/fsevents'
            listener_class = Vagrant::Syncer::Listeners::FSEvents
          when /linux/
            require_relative 'listeners/inotify'
            listener_class = Vagrant::Syncer::Listeners::INotify
          else
            require_relative 'listeners/listen'
            listener_class = Vagrant::Syncer::Listeners::Listen
          end
        end

        paths = []
        listener_excludes = []
        @rsync_synced_folders.each do |id, folder_opts|
          paths << File.expand_path(folder_opts[:hostpath],
            @machine.env.root_path)
          if folder_opts[:rsync__excludes]
            listener_excludes << folder_opts[:rsync__excludes]
          end
        end

        listener_name = listener_class.to_s.gsub(/^.*::/, '')

        change_callback = Proc.new do |changed|
          if listener_verbose
            @logger.info(listener_name + ": " + changed.join(', '))
          end
          @syncers.each do |syncer|
            syncer.sync(changed)
          end
        end

        listener = listener_class.new(
          paths,
          listener_excludes,
          listener_settings,
          change_callback
        )

        text = polling ? 'syncer.states.polling' : 'syncer.states.watching'
        paths.each do |path|
          @logger.info(I18n.t(text, {
            host_path: path,
            listener: listener_name,
            interval: listener_interval
          }))
        end

        listener.run
      end

    end
  end
end
