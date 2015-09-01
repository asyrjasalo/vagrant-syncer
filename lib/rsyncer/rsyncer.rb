require "vagrant/util/platform"
require "vagrant/util/subprocess"

module Vagrant
  module Rsyncer
    class Rsyncer

      def initialize(path, machine)
        @machine = machine
        @logger = machine.ui
        @host_path = parse_host_path(path[:source][:path])
        @guest_path = path[:target][:path]
        @exclude_args = parse_exclude_args(path[:source][:excludes])
        @owner_user = path[:target][:user]
        @owner_group = path[:target][:group]
        @ssh_username = machine.ssh_info[:username]
        @ssh_host = machine.ssh_info[:host]
        @ssh_command = parse_ssh_command(path[:target][:args][:ssh])
        @rsync_args = parse_rsync_args(path[:target][:args][:rsync])
        @command_opts = { workdir: machine.env.root_path.to_s }
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
          "#{@ssh_username}@#{@ssh_host}:#{@guest_path}",
        ].flatten

        result = Vagrant::Util::Subprocess.execute(*(command + [@command_opts]))
        if result.exit_code != 0
          @logger.error('Rsync failed: ' + result.stderr)
          @logger.error('The executed command was: ' + command.join(' '))
          return
        end

        @logger.info(result.stdout)  unless result.stdout.empty?
        @logger.success('Synced: ' + includes.join(', '))

        post_rsync_opts = {}
        post_rsync_opts[:chown] = true

        # TODO: chown only the changed file
        post_rsync_opts[:guestpath] = @guest_path

        post_rsync_opts[:owner] = @owner_user
        post_rsync_opts[:group] = @owner_group

        # default owner and group if not given by user
        post_rsync_opts[:owner] ||= @ssh_username
        # TODO: get user primary group over ssh
        post_rsync_opts[:group] ||= @ssh_username

        if @machine.guest.capability?(:rsync_post)
          @machine.guest.capability(:rsync_post, post_rsync_opts)
        end
      end

      private

      def parse_host_path(source_path)
        host_path = File.expand_path(source_path, @machine.env.root_path)
        host_path = Vagrant::Util::Platform.fs_real_path(host_path).to_s
        # Rsync on Windows expects Cygwin style paths
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
        excludes << '.vagrant/'
        excludes.uniq.map { |e| ["--exclude", e] }
      end

      def parse_ssh_command(ssh_args=nil)
        ssh_args ||= []

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

      def parse_rsync_args(rsync_args=nil)
        rsync_args ||= ["--verbose", "--archive", "--delete", "--compress",
          "--copy-links"]

        # on Windows, set a default chmod flag to avoid permission issues
        if Vagrant::Util::Platform.windows? && !rsync_args.any? { |arg| arg.start_with?("--chmod=") }
          # ensure all bits get masked
          rsync_args << "--chmod=ugo=rwX"

          # remove the -p option if --archive is enabled, otherwise new files
          # will not have the destination-default permissions
          rsync_args << "--no-perms"  if rsync_args.include?("--archive") || rsync_args.include?("-a")
        end

        # disable rsync's owner/group preservation (implied by --archive) unless
        # specifically requested, since we adjust owner/group later ourselves
        unless rsync_args.include?("--owner") || rsync_args.include?("-o")
          rsync_args << "--no-owner"
        end
        unless rsync_args.include?("--group") || rsync_args.include?("-g")
          rsync_args << "--no-group"
        end

        # tell local rsync to invoke remote rsync with sudo
        rsync_command = @machine.guest.capability(:rsync_command)
        rsync_args << "--rsync-path"<< rsync_command  if rsync_command

        rsync_args
      end

    end
  end
end