# auth_test.rb
require 'fog/openstack'

options = {
  :openstack_auth_uri      => URI.parse(ENV['EC2_URL']),
  :openstack_username      => ENV['AMAZON_ACCESS_KEY_ID'],
  :openstack_api_key       => ENV['AMAZON_SECRET_ACCESS_KEY'],
  :openstack_service_type  => 'identity',
  :openstack_endpoint_type => 'publicURL' }

Fog::OpenStack.authenticate_v2 options, {:ssl_verify_peer => false}