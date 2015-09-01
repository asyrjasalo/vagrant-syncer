require "vagrant/util/platform"
require "vagrant/util/subprocess"

module Vagrant
  module Rsyncer
    class Rsyncer

      def initialize(path, machine)
        @path = path
        @machine = machine
      end

      def sync(includes=nil)
        # host path
        host_path = @path[:source][:path]
        host_path = File.expand_path(host_path, @machine.env.root_path)
        host_path = Vagrant::Util::Platform.fs_real_path(host_path).to_s
        # Rsync on Windows expects Cygwin style paths
        if Vagrant::Util::Platform.windows?
          host_path = Vagrant::Util::Platform.cygwin_path(host_path)
        end
        # prevent creating directory inside directory
        if File.directory?(host_path) && !host_path.end_with?("/")
          host_path += "/"
        end

        # includes, i.e. files to be synced
        includes ||= [host_path]

        # guest path
        guest_path = @path[:target][:path]

        # ssh
        proxy_command = ""
        if @machine.ssh_info[:proxy_command]
          proxy_command = "-o ProxyCommand='#{@machine.ssh_info[:proxy_command]}' "
        end
        ssh_command = [
          "ssh -p #{@machine.ssh_info[:port]} " +
          proxy_command +
          @path[:target][:args][:ssh].join(' '),
          @machine.ssh_info[:private_key_path].map { |p| "-i '#{p}'" },
        ].flatten.join(' ')

        # excludes
        excludes = ['.vagrant/']
        if @path[:source][:excludes]
          excludes += @path[:source][:excludes].map(&:to_s)
          excludes.uniq!
        end

        # rsync args
        if @path[:target][:args][:rsync]
          rsync_args = @path[:target][:args][:rsync]
        else
          rsync_args = ["--verbose", "--archive", "--delete", "--compress",
            "--copy-links"]
        end

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

        # build up the full command to execute
        command = [
          "rsync",
          rsync_args,
          "-e", ssh_command,
          includes.map { |path| ["--include", path] },
          excludes.map { |e| ["--exclude", e] },
          host_path,
          "#{@machine.ssh_info[:username]}@#{@machine.ssh_info[:host]}:#{guest_path}",
        ].flatten

        command_opts = {}
        command_opts[:workdir] = @machine.env.root_path.to_s

        result = Vagrant::Util::Subprocess.execute(*(command + [command_opts]))
        if result.exit_code != 0
          @machine.ui.error('Rsync failed: ' + result.stderr)
          @machine.ui.error('The executed command was: ' + command.join(' '))
          return
        end

        @machine.ui.info(result.stdout)  unless result.stdout.empty?
        @machine.ui.success('Synced: ' + includes.join(', '))

        post_rsync_opts = {}
        post_rsync_opts[:chown] = true

        # TODO: chown only the changed file
        post_rsync_opts[:guestpath] = @path[:target][:path]

        post_rsync_opts[:owner] = @path[:target][:user]
        post_rsync_opts[:group] = @path[:target][:group]

        # default owner and group if not given by user
        post_rsync_opts[:owner] ||= @machine.ssh_info[:username]
        # TODO: get user primary group over ssh
        post_rsync_opts[:group] ||= @machine.ssh_info[:username]

        if @machine.guest.capability?(:rsync_post)
          @machine.guest.capability(:rsync_post, post_rsync_opts)
        end

      end
    end
  end
end