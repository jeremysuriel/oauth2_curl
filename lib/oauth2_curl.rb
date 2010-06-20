require 'rubygems'
require 'oauth2'
require 'optparse'
require 'ostruct'
require 'stringio'
require 'yaml'
require 'uri'

library_files = Dir[File.join(File.dirname(__FILE__), "/oauth2_curl/**/*.rb")]
library_files.each do |file|
  require file
end

module Oauth2Curl
  @options ||= Options.new
  class << self
    attr_accessor :options
  end

  class Exception < ::Exception
  end
end
