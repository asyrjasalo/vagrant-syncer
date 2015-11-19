module Vagrant
  module Syncer
    class Config < Vagrant.plugin(2, :config)

      attr_accessor :interval, :run_on_startup, :show_events, :ssh_args

      def initialize
        @interval       = UNSET_VALUE
        @show_events    = UNSET_VALUE
        @ssh_args       = UNSET_VALUE
        @run_on_startup = UNSET_VALUE
      end

      def finalize!
        @interval = 0.2          if @interval == UNSET_VALUE
        @run_on_startup = true   if @run_on_startup == UNSET_VALUE
        @show_events = false     if @show_events == UNSET_VALUE
        @ssh_args = [
          '-o StrictHostKeyChecking=no',
          '-o IdentitiesOnly=true',
          '-o UserKnownHostsFile=/dev/null'
        ] if @ssh_args == UNSET_VALUE
      end

    end
  end
end
