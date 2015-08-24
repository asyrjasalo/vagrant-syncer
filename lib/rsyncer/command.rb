module VagrantPlugins
  module Rsyncer
    class Command < Vagrant.plugin(2, :command)

      def self.synopsis
        "continuously rsync the changed files to the guest"
      end

      def execute
      end

    end
  end
end
