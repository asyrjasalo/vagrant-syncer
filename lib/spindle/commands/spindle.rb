module Vagrant
  module Spindle
    module Commands
      class Spindle < Vagrant.plugin(2, :command)

        def self.synopsis
          "continuously synchronizes changed files to the remote"
        end

        def execute
          with_target_vms do |machine|
            machine = Machine.new(machine)
            machine.full
            machine.listen
          end
          0
        end

      end
    end
  end
end