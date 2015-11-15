require 'vagrant/util/platform'

require_relative 'syncers/rsync'

module Vagrant
  module Syncer
    class Path

      def initialize(path_opts, machine)
        @logger = machine.ui
        @source_path = path_opts[:hostpath]
        @syncer = Syncers::Rsync.new(path_opts, machine)
        @absolute_path = File.expand_path(@source_path, machine.env.root_path)

        @listener_verbose = machine.config.syncer.show_events
        @listener_interval = machine.config.syncer.interval

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

        @listener_name = @listener_class.to_s.gsub(/^.*::/, '')

        listener_settings = {
          latency: @listener_interval
        }

        @listener = @listener_class.new(
          @absolute_path,
          path_opts[:rsync__excludes],
          listener_settings,
          change_callback
        )
      end

      def initial_sync
        @logger.info(I18n.t('syncer.states.initial', path: @absolute_path))
        @syncer.sync
      end

      def listen
        @logger.info(I18n.t('syncer.states.watching', {
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