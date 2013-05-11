require 'rubygems'

class Data_scheduled_actions 

  def initialize(owner)
     puts "Data_scheduled_actions.initialize"
     @ec2_main = owner  
  end 
  
 def all(options = {})
      @data = Array.new
      conn = @ec2_main.environment.as_connection
      if conn != nil
         begin 
            response = conn.describe_scheduled_actions(options)
            if response.status == 200
	       @data = response.body["DescribeScheduledActionsResult"]["ScheduledUpdateGroupActions"]
	    else   
	       @data = Array.new
	    end                  
         rescue
            puts "ERROR: getting all scheduled actions  #{$!}"
         end
      end   
      return @data
  end  

  def put_scheduled_update_group_action(auto_scaling_group_name, scheduled_action_name, time=nil, options = {}) 
       @data = false
       conn = @ec2_main.environment.as_connection
       if conn != nil
          response = conn.put_scheduled_update_group_action(auto_scaling_group_name, scheduled_action_name, time=nil, options) 
          if response.status == 200
 	     @data = true
  	  else   
 	     @data = false
 	  end                  
       else 
          raise "Connection Error"
       end   
       return @data
  end 
 
 
  def delete_scheduled_action(auto_scaling_group_name, scheduled_action_name)
       @data = false
       conn = @ec2_main.environment.as_connection
       if conn != nil
          response = conn.delete_scheduled_action(auto_scaling_group_name, scheduled_action_name)
          if response.status == 200
 	     @data = true
  	  else   
 	     @data = false
 	  end                  
       else 
          raise "Connection Error"
       end   
       return @data
  end 
  
  
 end