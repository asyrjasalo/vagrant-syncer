require 'vagrant/util/platform'

require_relative 'syncers/rsync'

module Vagrant
  module Spindle
    class Path

      attr_accessor :do_initial,
        :do_continuous,
        :absolute_path,
        :listener_class,
        :listener_interval

      def initialize(path, machine)
        @source_path = path[:source][:path]
        @syncer = Syncers::Rsync.new(path, machine)
        @absolute_path = File.expand_path(@source_path, machine.env.root_path)

        @do_initial = path[:source][:initial] || true
        @do_continuous = path[:source][:continuous] || true

        if path[:source][:listener]
          @listener_verbose = path[:source][:listener][:verbose]
          @listener_interval = path[:source][:listener][:interval]
        end

        @listener_verbose ||= false
        @listener_interval ||= 0.1

        @logger = machine.ui  if @listener_verbose

        if @do_continuous
          case Vagrant::Util::Platform.platform
          when /darwin/
            require_relative 'listeners/fsevents'
            @listener_class = Vagrant::Spindle::Listeners::FSEvents
          when /linux/
            require_relative 'listeners/inotify'
            @listener_class = Vagrant::Spindle::Listeners::INotify
          else
            require_relative 'listeners/listen'
            @listener_class = Vagrant::Spindle::Listeners::Listen
          end

          require_relative 'listeners/listen'
          @listener_class = Vagrant::Spindle::Listeners::Listen

          listener_settings = {
            latency: @listener_interval
          }

          @listener = @listener_class.new(
            @absolute_path,
            path[:source][:excludes],
            listener_settings,
            change_handler
          )
        end
      end

      def initial
        @syncer.sync
      end

      def listen
        @listener.run
      end

      private

      def change_handler
        Proc.new do |changed|
          @logger.warn(I18n.t('spindle.states.changed',
            paths: changed.to_a.join(', ')))  if @listener_verbose
          @syncer.sync(changed)
        end
      end

    end
  end
end