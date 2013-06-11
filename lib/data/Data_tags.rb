require 'rubygems'
require 'fog'

class Data_tags 

  def initialize(owner)
     puts "Data_tags.initialize"
     @ec2_main = owner  
  end 

  # Retrieve a list tags for resource.

  def all(resource=nil,type=nil)
      data = []
      filter = {}
      filter['resource-id'] = resource if resource != nil 
      filter['resource-type'] = type if resource != type 
      conn = @ec2_main.environment.connection
      if conn != nil
         begin 
           response = conn.describe_tags(filter)
           if response.status == 200
              data = response.body['tagSet']
           else 
              data = []
           end  
    	 rescue
            puts "ERROR: getting all tags  #{$!}"
         end
      end   
      return data
  end
   
end  