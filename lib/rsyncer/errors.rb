module VagrantPlugins
  module Rsyncer
    module Errors

      class RsyncerError < Vagrant::Errors::VagrantError
        error_namespace("rsyncer.errors")
      end

      class ConfigNotFound < RsyncerError
        error_key :config_not_found
      end

    end
  end
end
