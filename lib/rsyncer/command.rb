module Vagrant
  module Rsyncer
    class Command < Vagrant.plugin(2, :command)

      def self.synopsis
        "continuously synchronizes the file changes to the remote"
      end

      def execute
        with_target_vms do |machine|
          root_path = machine.env.root_path
          machine.config.rsyncer.settings[:paths].each do |path|
            rsyncer = Rsyncer.new(path, machine)
            if path[:source][:initial]
              machine.ui.info(I18n.t('rsyncer.states.initial'))
              rsyncer.sync
            end
            listen_opts = path[:source][:listen]
            next  unless listen_opts
            listen_path = File.expand_path(path[:source][:path], root_path)
            Listen.to(listen_path, listen_opts) { |modified, added, removed|
              rsyncer.sync(modified + added + removed)
            }.start
            machine.ui.info(I18n.t('rsyncer.states.watching', path: listen_path))
            sleep
          end
        end
        0
      end

    end
  end
end