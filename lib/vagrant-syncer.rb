begin
  require "vagrant"
rescue LoadError
  raise "This plugin must be run within Vagrant."
end

require 'syncer/actions'
require 'syncer/machine'
require 'syncer/plugin'
require 'syncer/version'

module Vagrant
  module Syncer

    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end

    I18n.load_path << File.expand_path("locales/en.yml", source_root)
    I18n.reload!
  end
end
