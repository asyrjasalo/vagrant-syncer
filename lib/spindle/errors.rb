module Vagrant
  module Spindle

    class Error < Errors::VagrantError
      error_namespace("spindle.errors")
    end

  end
end
