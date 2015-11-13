require 'listen'
require 'vagrant/util/busy'

require_relative 'syncers/rsync'

module Vagrant
  module Spindle
    class Path

      attr_accessor :do_initial, :do_continuous, :absolute_path

      def self.excludes_to_listen(exclude)
        exclude = exclude.gsub('**', '"GLOBAL"')
        exclude = exclude.gsub('*', '"PATH"')

        if exclude.start_with?('/')
          pattern = "^#{Regexp.escape(exclude[1..-1])}"
        else
          pattern = Regexp.escape(exclude)
        end

        pattern = pattern.gsub('"PATH"', "[^/]*")
        pattern = pattern.gsub('"GLOBAL"', ".*")

        Regexp.new(pattern)
      end

      def initialize(path, machine)
        @logger = machine.ui
        @source_path = path[:source][:path]
        @syncer = Syncers::Rsync.new(path, machine)

        @absolute_path = File.expand_path(@source_path, machine.env.root_path)
        @do_initial = path[:source][:initial] || true
        @do_continuous = path[:source][:continuous] || true

        if @do_continuous
          listen_ignores = []

          path[:source][:excludes].each do |pattern|
            listen_ignores << self.class.excludes_to_listen(pattern.to_s)
          end

          listener_settings = path[:source][:listener].merge(
            ignore!: listen_ignores,
            relative: true
          )
          @listener = Listen.to(@absolute_path, listener_settings, &callback)
        end
      end

      def to_s
        @source_path
      end

      def initial
        @syncer.sync
      end

      def listen
        queue = Queue.new
        callback = lambda do
          Thread.new { queue << true }
        end

        # Run the listener in a busy block, exit once we receive an interrupt
        Vagrant::Util::Busy.busy(callback) do
          @listener.start
          queue.pop
          @listener.stop  if @listener.state != :stopped
        end
      end

      private

      def callback
        Proc.new do |modified, added, removed|
          changed = modified + added + removed
          @logger.warn(I18n.t('spindle.states.changed', paths: changed.join(', ')))
          @syncer.sync(changed)
        end
      end

    end
  end
end