require 'listen'
require 'vagrant/util/busy'

require_relative 'syncers/rsync'

module Vagrant
  module Spindle
    class Path

      attr_accessor :do_initial, :do_continuous, :absolute_path

      # Convert Rsync exclude patterns to Listen gem.
      # Implementation partially from:
      # https://github.com/mitchellh/vagrant/blob/master/plugins/synced_folders/rsync/helper.rb#L11
      def self.excludes_to_listen(exclude)
        if exclude.start_with?("/")
          regexp = "^"
          exclude = exclude[1..-1]
        else
          regexp = ".*"
        end

        exclude = exclude.gsub("**", "|||GLOBAL|||")
        exclude = exclude.gsub("*", "|||PATH|||")
        exclude = exclude.gsub("|||PATH|||", "[^/]*")
        exclude = exclude.gsub("|||GLOBAL|||", ".*")
        regexp += Regexp.escape(exclude)

        Regexp.new(regexp)
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

          listener_settings = path[:source][:listener].merge(ignore: listen_ignores)
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
          @logger.info("Changed: " + changed.join(', '))
          @syncer.sync(changed)
        end
      end

    end
  end
end