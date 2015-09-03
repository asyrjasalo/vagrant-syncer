begin
  require "vagrant"
rescue LoadError
  raise "This plugin must be run within Vagrant."
end

require 'spindle/actions'
require 'spindle/machine'
require 'spindle/path'
require 'spindle/plugin'
require 'spindle/version'

module Vagrant
  module Spindle

    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end

    I18n.load_path << File.expand_path("locales/en.yml", source_root)
    I18n.reload!
  end
end