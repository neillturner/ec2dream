require 'rubygems'

class Data_auto_scaling_policies 

  def initialize(owner)
     puts "Data_auto_scaling_policies.initialize"
     @ec2_main = owner  
  end 
  
  def all(options)
      data = Array.new
      conn = @ec2_main.environment.as_connection
      if conn != nil
         begin
            response = conn.describe_policies(options)
            if response.status == 200
	       data = response.body["DescribePoliciesResult"]["ScalingPolicies"]
	    else   
	       data = Array.new
	    end                
         rescue
            puts "ERROR: getting all auto_scaling_policies  #{$!}"
         end
      end   
      return data
  end
 
 def put_scaling_policy(adjustment_type, auto_scaling_group_name, policy_name, scaling_adjustment, options = {})
       data = {}
       conn = @ec2_main.environment.as_connection
       if conn != nil
          response = conn.put_scaling_policy(adjustment_type, auto_scaling_group_name, policy_name, scaling_adjustment, options)
          if response.status == 200
 	     data = response.body["PutScalingPolicyResult"]
  	  else   
 	     data = {}
 	  end                  
       else 
          raise "Connection Error"
       end   
       return data
  end
 
 def execute_policy(policy_name, options = {})
       data = false
       conn = @ec2_main.environment.as_connection
       if conn != nil
          response = conn.execute_policy(policy_name, options)
          if response.status == 200
 	     data = true
 	  else   
 	     data = false
 	  end                  
       else 
          raise "Connection Error"
       end   
       return data
  end 
 
  def delete_policy(auto_scaling_group_name, policy_name)
     data = false
     conn = @ec2_main.environment.as_connection
     if conn != nil
        data = conn.delete_policy(auto_scaling_group_name, policy_name)
        if data.status == 200
	   data = true
	else   
	   data = false
	end   
     else 
        raise "Connection Error"
     end
     return data
  end   
  
  
 end