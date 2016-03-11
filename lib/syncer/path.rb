require 'vagrant/util/platform'

require_relative 'syncers/rsync'

module Vagrant
  module Syncer
    class Path

      def initialize(path_opts, machine, listener_polling=false)
        @logger = machine.ui
        @source_path = path_opts[:hostpath]
        @syncer = Syncers::Rsync.new(path_opts, machine)
        @absolute_path = File.expand_path(@source_path, machine.env.root_path)

        @listener_polling = listener_polling
        @listener_verbose = machine.config.syncer.show_events
        @listener_interval = machine.config.syncer.interval
        @force_listen_gem = machine.config.syncer.force_listen_gem

        listener_settings = {
          latency: @listener_interval,
          wait_for_delay: @listener_interval / 2
        }

        if @listener_polling
          require_relative 'listeners/listen'
          @listener_class = Vagrant::Syncer::Listeners::Listen
          listener_settings[:force_polling] = @listener_polling
        elsif @force_listen_gem
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

        @listener = @listener_class.new(
          @absolute_path,
          path_opts[:rsync__excludes],
          listener_settings,
          change_callback
        )
      end

      def initial_sync
        @logger.info(I18n.t('syncer.states.initial', path: @absolute_path))
        @syncer.sync([@source_path])
      end

      def listen
        text = @listener_polling ? 'syncer.states.polling' : 'syncer.states.watching'
        @logger.info(I18n.t(text, {
          path: @absolute_path,
          listener: @listener_name,
          interval: @listener_interval
        }))
        @listener.run
      end

      private

      def change_callback
        Proc.new do |changed|
          if @listener_verbose
            @logger.info(@listener_name + ": " + changed.join(', '))
          end
          @syncer.sync(changed)
        end
      end

    end
  end
end
