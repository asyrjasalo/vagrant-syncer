require 'listen'
require 'vagrant/util/busy'

require_relative 'syncers/rsync'

module Vagrant
  module Spindle
    class Path

      attr_accessor :initial_enabled, :listen_enabled

      # Convert Rsync exclude pattern to a regular expression.
      # Implementation from:
      # https://github.com/mitchellh/vagrant/blob/master/plugins/synced_folders/rsync/helper.rb#L11
      def self.ignore_to_listen(exclude)
        exclude = exclude.gsub("**", "|||GLOBAL|||")
        exclude = exclude.gsub("*", "|||PATH|||")
        exclude = exclude.gsub("|||PATH|||", "[^/]*")
        exclude = exclude.gsub("|||GLOBAL|||", ".*")
        Regexp.new(exclude)
      end

      def initialize(path, machine)
        @source_path = path[:source][:path]
        @syncer = Syncers::Rsync.new(path, machine)

        @initial_enabled = !path[:source][:initial].nil?
        @listen_enabled = !path[:source][:listen].nil?

        if @listen_enabled
          listen_ignores = []
          abs_source_path = File.expand_path(@source_path, machine.env.root_path)
          path[:source][:excludes].each do |pattern|
            listen_ignores << self.class.ignore_to_listen(pattern.to_s)
          end

          listen_settings = path[:source][:listen].merge(ignore: listen_ignores)
          @listener = Listen.to(abs_source_path, listen_settings, &callback)
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
          @syncer.sync(modified + added + removed)
        end
      end

    end
  end
end