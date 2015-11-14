module Vagrant
  module Syncer
    class Config < Vagrant.plugin(2, :config)

      attr_accessor :continuous, :initial, :interval, :show_events, :ssh_args

      def initialize
        @continuous  = UNSET_VALUE
        @initial     = UNSET_VALUE
        @interval    = UNSET_VALUE
        @show_events = UNSET_VALUE
        @ssh_args    = UNSET_VALUE
      end

      def finalize!
        @continuous = true    if @continuous == UNSET_VALUE
        @initial = true       if @initial == UNSET_VALUE
        @interval = 0.1       if @interval == UNSET_VALUE
        @show_events = false  if @show_events == UNSET_VALUE
        @ssh_args = nil       if @ssh_args == UNSET_VALUE
      end

    end
  end
end
