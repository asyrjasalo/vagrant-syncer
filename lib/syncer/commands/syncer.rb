module Vagrant
  module Syncer
    module Commands
      class Syncer < Vagrant.plugin(2, :command)

        def self.synopsis
          "start auto-rsyncing"
        end

        def execute
          with_target_vms do |machine|
            machine = Machine.new(machine)
            machine.full_sync
            machine.listen
          end
          0
        end

      end
    end
  end
end
