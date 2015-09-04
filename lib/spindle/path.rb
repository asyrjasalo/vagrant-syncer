require 'listen'
require 'vagrant/util/busy'

require_relative 'syncers/rsync'

module Vagrant
  module Spindle
    class Path

      attr_accessor :initial_enabled, :listen_enabled

      def initialize(path, machine)
        @source_path = path[:source][:path]
        @syncer = Syncers::Rsync.new(path, machine)

        @initial_enabled = !path[:source][:initial].nil?
        @listen_enabled = !path[:source][:listen].nil?

        if @listen_enabled
          abs_source_path = File.expand_path(@source_path, machine.env.root_path)
          @listener = Listen.to(abs_source_path, path[:source][:listen], &callback)
        end
      end

      def to_s
        @source_path
      end

      def initial
        @syncer.sync
      end

      def listen
        # Implementation copied from:
        # https://github.com/mitchellh/vagrant/blob/d5458247c7490f0eff79d3e39679a22c5d67ae81/plugins/synced_folders/rsync/command/rsync_auto.rb#L131
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
          @syncer.sync(modified + added + removed)
        end
      end

    end
  end
end