require 'listen'
require 'vagrant/util/busy'

require_relative 'syncers/rsync'

module Vagrant
  module Spindle
    class Path

      attr_accessor :initial_enabled, :listen_enabled

      # Forked from:
      # https://github.com/mitchellh/vagrant/blob/master/plugins/synced_folders/rsync/helper.rb#L11
      # TODO: Fix it
      def self.rsync_exclude_to_listen(path, exclude)
        start_anchor = false

        if exclude.start_with?("/")
          start_anchor = true
          exclude      = exclude[1..-1]
        end

        path   = "#{path}/" if !path.end_with?("/")
        regexp = "^#{Regexp.escape(path)}"
        regexp += ".*" if !start_anchor

        exclude = exclude.gsub("**", "|||GLOBAL|||")
        exclude = exclude.gsub("*", "|||PATH|||")
        exclude = exclude.gsub("|||PATH|||", "[^/]*")
        exclude = exclude.gsub("|||GLOBAL|||", ".*")
        regexp += exclude

        Regexp.new(regexp)
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
            listen_ignores << self.class.rsync_exclude_to_listen(abs_source_path,
              pattern.to_s)
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