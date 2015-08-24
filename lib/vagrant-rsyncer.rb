require "rsyncer/plugin"


module VagrantPlugins
  module Rsyncer

    lib_path = Pathname.new(File.expand_path("../rsyncer", __FILE__))
    autoload :Errors, lib_path.join("errors")

  end
end