require Vagrant.source_root.join("plugins/synced_folders/rsync/helper")

module Vagrant
  module Rsyncer
    class Command < Vagrant.plugin(2, :command)

      def self.synopsis
        "does a full sync and starts the rsyncer monitor"
      end

      def execute
        with_target_vms do |machine|
          opts = {}
          opts[:hostpath] = machine.config.rsyncer.settings['paths']['source']
          opts[:guestpath] = machine.config.rsyncer.settings['paths']['target']
          opts[:owner] = machine.config.rsyncer.settings['target']['user']
          opts[:group] = machine.config.rsyncer.settings['target']['group']
          opts[:exclude] = machine.config.rsyncer.settings['excludes']
          opts[:verbose] = machine.config.rsyncer.settings['verbose']
          opts[:args] = machine.config.rsyncer.settings['args']['rsync']
          opts[:args] <<  machine.config.rsyncer.settings['target']['permissions']
          opts[:args] << '-z'

          ssh_settings = machine.ssh_info
          if ssh_settings
            machine.ui.info("Doing initial full sync to get the guest up to date.")
            VagrantPlugins::SyncedFolderRSync::RsyncHelper.rsync_single(
              machine, ssh_settings, opts)
          end


          paths = [opts[:hostpath]]
          @logger = machine.ui

          ignores = []
          paths.each do |path|
            if opts
              Array(opts[:exclude]).each do |pattern|
                ignores << VagrantPlugins::SyncedFolderRSync::RsyncHelper.exclude_to_regexp(path, pattern.to_s)
              end
            end
          end

          latency = machine.config.rsyncer.settings['latency']

          case RUBY_PLATFORM
          when /darwin/
            require_relative('listeners/fsevents')
            Listeners::FSEvents.new(paths, ignores, latency, @logger, self.method(:callback)).run
          when /linux/
            require_relative('listeners/inotify')
            Listeners::INotify.new(paths, ignores, latency, @logger, self.method(:callback)).run
          when /cygwin|mswin|mingw|bccwin|wince|emx/
            require_relative('listeners/wdm')
            Listeners::WDM.new(paths, ignores, latency, @logger, self.method(:callback)).run
          else
            raise Errors::OSNotSupportedError
          end
        end

        0
      end

      def callback(paths, ignores, modified)
        @logger.info("Changes detected: #{modified.to_a.join(',')}")

        tosync = []
        paths.each do |hostpath, folders|
          found = catch(:done) do
            modified.each do |changed|
              match = nil
              ignores.each do |ignore|
                next unless match.nil?
                match = ignore.match(changed)
              end

              next unless match.nil?
              throw :done, true if changed.start_with?(hostpath)
            end

            false
          end

          tosync << folders if found
        end

        # Sync all the folders that need to be synced
        tosync.each do |folders|
          folders.each do |opts|
            ssh_info = opts[:machine].ssh_info
            do_rsync(opts[:machine], ssh_info, opts[:opts]) if ssh_info
          end
        end
      end

      private

        def do_rsync(machine, ssh_info, opts)
          start_time = Time.new
          VagrantPlugins::SyncedFolderRSync::RsyncHelper.rsync_single(machine, ssh_info, opts)
          end_time = Time.new
          machine.ui.info(I18n.t(
            "vagrant_gatling_rsync.gatling_ran",
            date: end_time.strftime(machine.config.gatling.time_format),
            milliseconds: (end_time - start_time) * 1000))
        end

    end
  end
end