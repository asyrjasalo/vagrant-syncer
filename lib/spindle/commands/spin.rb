require 'listen'

module Vagrant
  module Spindle
    module Commands
      class Spin < Vagrant.plugin(2, :command)

        def self.synopsis
          "synchronizes all the files to get the remote up to date"
        end

        def execute
          with_target_vms do |machine|
            machine = Machine.new(machine)
            machine.full
          end
          0
        end

      end
    end
  end
end