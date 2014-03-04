require 'chefspec'
require 'chefspec/berkshelf'
require 'fauxhai'

RSpec.configure do |config|
  config.cookbook_path = ['./cookbooks']
end
