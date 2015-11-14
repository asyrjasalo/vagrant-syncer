module Vagrant
  module Syncer
    module Commands
      class Syncer < Vagrant.plugin(2, :command)

        def self.synopsis
          "continuously rsyncs the changed files to the guest"
        end

        def execute
          with_target_vms do |machine|
            unless machine.config.syncer.settings
              raise Vagrant::Errors::VagrantError.new,
                I18n.t('syncer.config.undefined')
            end

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