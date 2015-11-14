require "vagrant/util/platform"
require "vagrant/util/subprocess"

module Vagrant
  module Syncer
    module Syncers
      class Rsync

        def initialize(path_opts, machine)
          @machine = machine
          @logger = machine.ui

          @machine_path = machine.env.root_path.to_s
          @host_path = parse_host_path(path_opts[:hostpath])
          @rsync_args = parse_rsync_args(path_opts[:rsync__args])
          @ssh_command = parse_ssh_command(machine.config.syncer.ssh_args)
          @exclude_args = parse_exclude_args(path_opts[:rsync__excludes])

          ssh_username = machine.ssh_info[:username]
          ssh_host = machine.ssh_info[:host]
          guest_path = path_opts[:guestpath]
          @ssh_target = "#{ssh_username}@#{ssh_host}:#{guest_path}"
        end

        def sync(changed_paths=nil)
          changed_paths ||= [@host_path]

          command = [
            "rsync",
            @rsync_args,
            "-e", @ssh_command,
            changed_paths.map { |path| ["--include", path] },
            @exclude_args,
            @host_path,
            @ssh_target
          ].flatten

          result = Vagrant::Util::Subprocess.execute(
            *(command + [{ workdir: @machine_path }])
          )

          if result.exit_code != 0
            @logger.error(I18n.t('syncer.rsync.failed',
              error: result.stderr))
            @logger.error(I18n.t('syncer.rsync.failed_command',
              command: command.join(' ')))
          else
            @logger.success(I18n.t('syncer.rsync.succeeded',
              output: result.stdout))  unless result.stdout.empty?
          end
        end

        private

        def parse_host_path(host_dir)
          abs_host_path = File.expand_path(host_dir, @machine_path)
          abs_host_path = Vagrant::Util::Platform.fs_real_path(abs_host_path).to_s

          # Rsync on Windows expects Cygwin style paths
          if Vagrant::Util::Platform.windows?
            abs_host_path = Vagrant::Util::Platform.cygwin_path(abs_host_path)
          end

          # Ensure path ends with '/' to prevent creating directory inside directory
          if !abs_host_path.end_with?("/")
            abs_host_path += "/"
          end

          abs_host_path
        end

        def parse_exclude_args(excludes=nil)
          excludes ||= []
          excludes << '.vagrant/'  # in any case, exclude .vagrant directory
          excludes.uniq.map { |e| ["--exclude", e] }
        end

        def parse_ssh_command(ssh_args=nil)
          ssh_args ||= [
            '-o StrictHostKeyChecking=no',
            '-o UserKnownHostsFile=/dev/null'
          ]

          proxy_command = ""
          if @machine.ssh_info[:proxy_command]
            proxy_command = "-o ProxyCommand='#{@machine.ssh_info[:proxy_command]}' "
          end

          ssh_command = [
            "ssh -p #{@machine.ssh_info[:port]} " +
            proxy_command +
            ssh_args.join(' '),
            @machine.ssh_info[:private_key_path].map { |p| "-i '#{p}'" },
          ].flatten.join(' ')
        end

        def parse_rsync_args(rsync_args=nil, permissions=nil)
          rsync_args ||= ["--archive", "--delete", "--compress",
            "--copy-links", "--verbose"]

          # This is the default rsync output unless overridden
          rsync_args.unshift("--out-format=%L%n")

          rsync_chmod_args_given = rsync_args.any? do |arg|
            arg.start_with?("--chmod=")
          end

          # On Windows, enable all non-masked bits to avoid permission issues
          if Vagrant::Util::Platform.windows? && !rsync_chmod_args_given
            rsync_args << "--chmod=ugo=rwX"

            # Remove the -p option if --archive (equals -rlptgoD) is given
            # Otherwise new files won't get the destination-default permissions
            if rsync_args.include?("--archive") || rsync_args.include?("-a")
              rsync_args << "--no-perms"
            end
          end

          rsync_args
        end

      end
    end
  end
end