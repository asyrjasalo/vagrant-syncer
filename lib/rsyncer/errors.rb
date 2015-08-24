module Vagrant
  module Rsyncer

    class Error < Errors::VagrantError
      error_namespace("rsyncer.errors")
    end

  end
end
