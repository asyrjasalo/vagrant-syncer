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
          @rsync_args = parse_rsync_args(path_opts[:rsync__args], path_opts[:rsync__rsync_path])
          @rsync_verbose = path_opts[:rsync__verbose] || false
          @ssh_command = parse_ssh_command(machine.config.syncer.ssh_args)
          @exclude_args = parse_exclude_args(path_opts[:rsync__exclude])

          ssh_username = machine.ssh_info[:username]
          ssh_host = machine.ssh_info[:host]
          @ssh_target = "#{ssh_username}@#{ssh_host}:#{path_opts[:guestpath]}"

          @vagrant_command_opts = {
            workdir: @machine_path
          }

          @vagrant_rsync_opts = {
            guestpath: path_opts[:guestpath],
            chown: path_opts[:rsync__chown],
            owner: path_opts[:owner],
            group: path_opts[:group]
          }
          @vagrant_rsync_opts[:chown] ||= true
          @vagrant_rsync_opts[:owner] ||= ssh_username
          if @vagrant_rsync_opts[:group].nil?
            machine.communicate.execute('id -gn') do |type, output|
              @vagrant_rsync_opts[:group] = output.chomp  if type == :stdout
            end
          end
        end

        def sync(changed_paths=nil)
          changed_paths ||= [@host_path]

          rsync_command = [
            "rsync",
            @rsync_args,
            "-e", @ssh_command,
            changed_paths.map { |path| ["--include", path] },
            @exclude_args,
            @host_path,
            @ssh_target
          ].flatten

          rsync_vagrant_command = rsync_command + [@vagrant_command_opts]
          if @rsync_verbose
            @vagrant_command_opts[:notify] = [:stdout, :stderr]
            result = Vagrant::Util::Subprocess.execute(*rsync_vagrant_command) do |io_name, data|
              data.each_line do |line|
                if io_name == :stdout
                  @logger.success("Rsync: #{line}")
                elsif io_name == :stderr && !line =~ /Permanently added/
                  @logger.warn("Rsync: #{line}")
                end
              end
            end
          else
            result = Vagrant::Util::Subprocess.execute(*rsync_vagrant_command)
          end

          if result.exit_code != 0
            @logger.error(I18n.t('syncer.rsync.failed', error: result.stderr))
            @logger.error(I18n.t('syncer.rsync.failed_command', command: rsync_command.join(' ')))
            return
          end

          # Set owner/group after the files are transferred
          if @machine.guest.capability?(:rsync_post)
            @machine.guest.capability(:rsync_post, @vagrant_rsync_opts)
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
          abs_host_path += "/"  if !abs_host_path.end_with?("/")

          abs_host_path
        end

        def parse_exclude_args(excludes=nil)
          excludes ||= []
          excludes << '.vagrant/'  # in any case, exclude .vagrant directory
          excludes.uniq.map { |e| ["--exclude", e] }
        end

        def parse_ssh_command(ssh_args)
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

        def parse_rsync_args(rsync_args=nil, rsync_path=nil)
          rsync_args ||= ["--archive", "--delete", "--compress", "--copy-links", "--verbose"]

          # This is the default rsync output unless overridden by user
          rsync_args.unshift("--out-format=%L%n")

          rsync_chmod_args_given = rsync_args.any? { |arg| arg.start_with?("--chmod=") }

          # On Windows, enable all non-masked bits to avoid permission issues
          if Vagrant::Util::Platform.windows? && !rsync_chmod_args_given
            rsync_args << "--chmod=ugo=rwX"

            # Remove the -p option if --archive (equals -rlptgoD) is given
            # Otherwise new files won't get the destination-default permissions
            if rsync_args.include?("--archive") || rsync_args.include?("-a")
              rsync_args << "--no-perms"
            end
          end

          # Disable rsync's owner/group preservation (implied by --archive) unless
          # explicitly requested, since we adjust owner/group later ourselves
          unless rsync_args.include?("--owner") || rsync_args.include?("-o")
            rsync_args << "--no-owner"
          end
          unless rsync_args.include?("--group") || rsync_args.include?("-g")
            rsync_args << "--no-group"
          end

          # Invoke remote rsync with sudo to allow owner and group settings to work
          if !rsync_path && @machine.guest.capability?(:rsync_command)
            rsync_path = @machine.guest.capability(:rsync_command)
          end
          rsync_args << "--rsync-path" << rsync_path  if rsync_path

          rsync_args
        end

      end
    end
  end
end
