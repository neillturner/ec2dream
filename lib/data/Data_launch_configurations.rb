require 'rubygems'

class Data_launch_configurations 

  def initialize(owner)
     puts "Data_launch_configurations.initialize"
     @ec2_main = owner  
  end 
  
  def all
      data = Array.new
      conn = @ec2_main.environment.as_connection
      if conn != nil
         begin 
               x = conn.configurations.all
               x.each do |y|
                  r= {}
                  r[:launch_configuration_name] =  y.id
                  r[:created_time] = y.created_at.to_s
                  r[:security_groups] = y.security_groups
		  r[:image_id] = y.image_id
		  r[:kernel_id] = y.kernel_id
		  r[:user_data] = y.user_data
		  r[:instance_type] = y.instance_type
		  r[:key_name] = y.key_name
		  r[:block_device_mappings] = y.block_device_mappings
		  # new fields
		  r[:instance_monitoring] = y.instance_monitoring
		  r[:arn] = y.arn
                  data.push(r)
               end
         rescue
            puts "ERROR: getting all launch_configurations  #{$!}"
         end
      end   
      return data
  end
 
  def get(id) 
      r = {}
      conn = @ec2_main.environment.as_connection
      if conn != nil
         y = conn.configurations.get(id)
                  r= {}
                  r[:launch_configuration_name] =  y.id
                  r[:created_time] = y.created_at.to_s
                  r[:security_groups] = y.security_groups
		  r[:image_id] = y.image_id
		  r[:kernel_id] = y.kernel_id
		  r[:ramdisk_id] = y.ramdisk_id
		  r[:user_data] = y.user_data
		  r[:instance_type] = y.instance_type
		  r[:key_name] = y.key_name
		  r[:block_device_mappings] = y.block_device_mappings
		  # new fields
		  r[:instance_monitoring] = y.instance_monitoring
		  r[:arn] = y.arn
		  return r
      else 
         raise "Connection Error"
      end
      return r
  end 
 
   
  def create_launch_configuration(image_id, instance_type, launch_configuration_name, options = {})
      data = nil
      conn = @ec2_main.environment.as_connection
      if conn != nil
            data = conn.create_launch_configuration(image_id, instance_type, launch_configuration_name, options )
            if data.status == 200
	       data = data.body["launch_configuration"]
	    else   
	       data = nil
	    end   
       else 
         raise "Connection Error"
      end
      return data
  end 
  
  def delete_launch_configuration(id)
     data = false
     conn = @ec2_main.environment.as_connection
     if conn != nil
        data = conn.delete_launch_configuration(id)
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