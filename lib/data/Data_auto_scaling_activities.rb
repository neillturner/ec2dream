require 'rubygems'

class Data_auto_scaling_activities 

  def initialize(owner)
     puts "Data_auto_scaling_activities.initialize"
     @ec2_main = owner  
  end 
  
  
  
 def all(options = {})
      data = Array.new
      conn = @ec2_main.environment.as_connection
      if conn != nil
         begin 
            response = conn.describe_scaling_activities(options)
            if response.status == 200
	       data = response.body["DescribeScalingActivitiesResult"]["Activities"]
	    else   
	       data = Array.new
	    end                  
         rescue
            puts "ERROR: getting all auto_scaling_activities  #{$!}"
         end
      end   
      return data
  end
   
 end