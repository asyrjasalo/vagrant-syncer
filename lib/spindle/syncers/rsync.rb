require "vagrant/util/platform"
require "vagrant/util/subprocess"

module Vagrant
  module Spindle
    module Syncers
      class Rsync

        def initialize(path, machine)
          @machine = machine
          @logger = machine.ui

          @machine_path = machine.env.root_path.to_s
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
          command = [
            "rsync",
            @rsync_args,
            "-e", @ssh_command,
            @exclude_args,
            @host_path,
            @ssh_target
          ].flatten

          result = Vagrant::Util::Subprocess.execute(
            *(command + [{ workdir: @machine_path }])
          )

          if result.exit_code != 0
            @logger.error(I18n.t('spindle.rsync.failed',
              error: result.stderr))
            @logger.error(I18n.t('spindle.rsync.failed_command',
              command: command.join(' ')))
          else
            unless result.stdout.empty?
              @logger.success(result.stdout.gsub("#{@machine_path[1..-1]}/", ''))
            end
          end
        end

        private

        def parse_host_path(source_path)
          host_path = File.expand_path(source_path, @machine_path)
          host_path = Vagrant::Util::Platform.fs_real_path(host_path).to_s

          # Rsync on Windows expects Cygwin style paths
          if Vagrant::Util::Platform.windows?
            host_path = Vagrant::Util::Platform.cygwin_path(host_path)
          end

          # Prevent creating directory inside directory
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

          # This is the default rsync output unless overridden
          rsync_args.unshift("--out-format=#{I18n.t('spindle.rsync.success')}" +
            "%L%f (%bB)")

          # If --chmod args are given to rsync, prefer them instead
          rsync_chmod_args_given = rsync_args.any? do |arg|
            arg.start_with?("--chmod=")
          end

          if !rsync_chmod_args_given
            # On Windows, enable all non-masked bits to avoid permission issues
            if Vagrant::Util::Platform.windows?
              rsync_args << "--chmod=ugo=rwX"

              # Remove the -p option if --archive (equals -rlptgoD) is given
              # Otherwise new files won't get the destination-default permissions
              if rsync_args.include?("--archive") || rsync_args.include?("-a")
                rsync_args << "--no-perms"
              end
            else
              # On other OSes, convert our config defined permissions to --chmod args
              if permissions
                rsync_args << "--chmod=u=#{permissions[:user]}"   if permissions[:user]
                rsync_args << "--chmod=g=#{permissions[:group]}"  if permissions[:group]
                rsync_args << "--chmod=o=#{permissions[:other]}"  if permissions[:other]
              end
            end
          end

          rsync_args
        end

      end
    end
  end
end