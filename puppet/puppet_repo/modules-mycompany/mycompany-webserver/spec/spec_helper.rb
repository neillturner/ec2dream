require 'puppet'
require 'rubygems'
require 'rspec-puppet'

RSpec.configure do |c|
  #c.module_path = File.join(File.dirname(__FILE__), '../../')
  c.module_path = '/var/local/pocketknife/modules:/var/local/pocketknife/modules-mycompany'
  c.manifest = './spec/site.pp'
end
