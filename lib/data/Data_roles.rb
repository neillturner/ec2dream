require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

class Data_roles

  def initialize(owner)
    puts "Data_roles.initialize"
    @ec2_main = owner
  end
  #
  # Retrieve a list of IAM Roles.
  #
  def all
    data = []
    conn = @ec2_main.environment.iam_connection
    if conn != nil
      begin
        response = conn.list_roles()
        if response.status == 200
          data = response.body["Roles"]
        end
      rescue
        puts "ERROR: getting all roles  #{$!}"
      end
    end
    return data
  end
end
