require 'chefspec'
require 'fauxhai'

RSpec.configure do |config|
  config.cookbook_path = ['/var/local/pocketknife/cookbooks','/var/local/pocketknife/site-cookbooks']
end
