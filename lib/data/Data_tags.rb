require 'rubygems'
require 'fog'

class Data_tags 

  def initialize(owner)
     puts "Data_tags.initialize"
     @ec2_main = owner  
  end 

  # Retrieve a list tags for resource.

  def all(resource)
      data = []
      conn = @ec2_main.environment.connection
      if conn != nil
         begin 
           response = conn.describe_tags({'resource-id' => resource})
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