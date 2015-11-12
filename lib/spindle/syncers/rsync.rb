require "vagrant/util/platform"
require "vagrant/util/subprocess"

module Vagrant
  module Spindle
    module Syncers
      class Rsync

        def initialize(path, machine)
          @machine = machine
          @logger = machine.ui

          @host_path = parse_host_path(path[:source][:path])
          @rsync_args = parse_rsync_args(path[:target][:args][:rsync],
            path[:target][:permissions])
          @ssh_command = parse_ssh_command(path[:target][:args][:ssh])
          @exclude_args = parse_exclude_args(path[:source][:excludes])

          ssh_username = machine.ssh_info[:username]
          ssh_host = machine.ssh_info[:host]
          guest_path = path[:target][:path]
          @ssh_target = "#{ssh_username}@#{ssh_host}:#{guest_path}"
        end

        def sync(includes=nil)
          includes ||= [@host_path]

          command = [
            "rsync",
            @rsync_args,
            "-e", @ssh_command,
            includes.map { |path| ["--include", path] },
            @exclude_args,
            @host_path,
            @ssh_target
          ].flatten

          result = Vagrant::Util::Subprocess.execute(
            *(command + [{ workdir: @machine.env.root_path.to_s }])
          )

          if result.exit_code != 0
            @logger.error('Rsync failed: ' + result.stderr)
            @logger.error('The executed command was: ' + command.join(' '))
          else
            @logger.success('Rsynced: ' + includes.join(', '))
            @logger.success(result.stdout)  unless result.stdout.empty?
          end
        end

        private

        def parse_host_path(source_path)
          host_path = File.expand_path(source_path, @machine.env.root_path)
          host_path = Vagrant::Util::Platform.fs_real_path(host_path).to_s

          # rsync on Windows expects Cygwin style paths
          if Vagrant::Util::Platform.windows?
            host_path = Vagrant::Util::Platform.cygwin_path(host_path)
          end

          # prevent creating directory inside directory
          if File.directory?(host_path) && !host_path.end_with?("/")
            host_path += "/"
          end

          host_path
        end

        def parse_exclude_args(excludes=nil)
          excludes ||= []
          excludes << '.vagrant/'  # always exclude .vagrant directory
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
          rsync_args ||= ["--archive", "--force", "--delete"]

          # if --chmod args given to rsync, prefer them instead
          rsync_chmod_args_given = rsync_args.any? do |arg|
            arg.start_with?("--chmod=")
          end

          # otherwise convert our given permissions to --chmod args
          if permissions && !rsync_chmod_args_given
            rsync_args << "--chmod=u=#{permissions[:user]}"   if permissions[:user]
            rsync_args << "--chmod=g=#{permissions[:group]}"  if permissions[:group]
            rsync_args << "--chmod=o=#{permissions[:other]}"  if permissions[:other]
          end

          # disable rsync's owner/group preservation (implied by --archive) unless
          # specifically requested, since we adjust owner/group later ourselves
          #unless rsync_args.include?("--owner") || rsync_args.include?("-o")
          #  rsync_args << "--no-owner"
          #end

          #unless rsync_args.include?("--group") || rsync_args.include?("-g")
          #  rsync_args << "--no-group"
          #end

          # invoke remote rsync with sudo
          #rsync_command = @machine.guest.capability(:rsync_command)
          #rsync_args << "--rsync-path"<< rsync_command  if rsync_command

          rsync_args
        end

      end
    end
  end
end