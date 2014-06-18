#
#   LIST NODES
#
#   sample code to list nodes from a chef server to demostrate using the chef server api
#   the first parameter is the environment name
#   to run
#     ruby list_nodes.rb myenv
#  ofcourse the chef_server_url, client_name and signing_key_filename must be set.
#



require 'rubygems'
require 'chef/config'
require 'chef/log'
require 'chef/rest'
require 'chef/node'
require 'chef/search/query'

chef_server_url = 'https://mychefserver:8443'
client_name = "nturner"
signing_key_filename='C:/repository/keys/nturner.pem'

rest = Chef::REST.new(chef_server_url, client_name, signing_key_filename)
nodes = rest.get_rest("/nodes")
#puts nodes
JSON.create_id = ""
env = ARGV.shift
puts "Environment                               fqdn                                Node Name                    IP Address            Run List"
puts "-----------------------------------------------------------------------------------------------------------------------------------------"
nodes.each do |k,v|
#    puts k,v
    node = rest.get_rest("/nodes/#{k}/")
    puts "#{node.chef_environment}   #{node.fqdn.rjust(40)} #{node.name.rjust(40)}  #{node.ipaddress.rjust(20)} #{node.run_list}" if node.chef_environment == env
end


