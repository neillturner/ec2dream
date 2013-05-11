require 'rubygems'
require 'net/http'
require 'resolv'
require 'fog'

class Data_elb

  def initialize(owner)
     puts "Data_elb.initialize"
     @ec2_main = owner  
  end 

  def apply_security_groups_to_load_balancer(security_group_ids, lb_name)
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.apply_security_groups_to_load_balancer(security_group_ids, lb_name)
        if response.status == 200
           data = response.body('ApplySecurityGroupsToLoadBalancer')
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def attach_load_balancer_to_subnets(subnet_ids, lb_name)
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.attach_load_balancer_to_subnets(subnet_ids, lb_name)
        if response.status == 200
           data = response.body['AttachLoadBalancerToSubnetsResult']
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def configure_health_check(lb_name, health_check)
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.configure_health_check(lb_name, health_check)
        if response.status == 200
           data = response.body['ConfigureHealthCheckResult']
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def create_app_cookie_stickiness_policy(lb_name, policy_name, cookie_name)
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.create_app_cookie_stickiness_policy(lb_name, policy_name, cookie_name)
        if response.status == 200
           data = {}
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def create_lb_cookie_stickiness_policy(lb_name, policy_name, cookie_expiration_period=nil)
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.create_lb_cookie_stickiness_policy(lb_name, policy_name, cookie_expiration_period)
        if response.status == 200
           data = {}
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def create_load_balancer(availability_zones, lb_name, listeners, options = {})
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.create_load_balancer(availability_zones, lb_name, listeners, options)
        if response.status == 200
           data = response.body['CreateLoadBalancerResult']
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def create_load_balancer_listeners(lb_name, listeners)
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.create_load_balancer_listeners(lb_name, listeners)
        if response.status == 200
           data = {}
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def create_load_balancer_policy(lb_name, name, type_name, attributes = {})
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.create_load_balancer_policy(lb_name, name, type_name, attributes)
        if response.status == 200
           data = {}
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def delete_load_balancer(lb_name)
     data = false
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.delete_load_balancer(lb_name)
        if response.status == 200
           data = true
	else
	   data = false
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def delete_load_balancer_listeners(lb_name, load_balancer_ports)
     data = false
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.delete_load_balancer_listeners(lb_name, load_balancer_ports)
        if response.status == 200
           data = true
	else
	   data = false
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def delete_load_balancer_policy(lb_name, policy_name)
     data = false
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.delete_load_balancer_policy(lb_name, policy_name)
        if response.status == 200
           data = true
	else
	   data = false
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def deregister_instances_from_load_balancer(instance_ids, lb_name)
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.deregister_instances_from_load_balancer(instance_ids, lb_name)
        if response.status == 200
           data = response.body['DeregisterInstancesFromLoadBalancerResult']
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def describe_instance_health(lb_name, instance_ids = [])
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
        begin 
	   response = conn.describe_instance_health(lb_name, instance_ids)
           if response.status == 200
              data = response.body['DescribeInstanceHealthResult']['InstanceStates']
            else
	      data = {}
           end
        rescue 
           puts "ERROR: describe_instance_health #{$!}"
        end
     end    
  end
  
  def describe_load_balancers(options = {})
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
        begin 
	   response = conn.describe_load_balancers(options = {})
           if response.status == 200
              data = response.body['DescribeLoadBalancersResult']['LoadBalancerDescriptions']
 	   else
	      data = {}
           end
        rescue 
           puts "ERROR: describe_load_balancers #{$!}"
        end
     end 
     return data
  end
  
  def describe_load_balancer_policies(lb_name = nil, names = [])
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
        begin 
	   response = conn.describe_load_balancer_policies(lb_name, names)
           if response.status == 200
              data = response.body['DescribeLoadBalancerPoliciesResult']['PolicyDescriptions']
	   else
	      data = {}
           end
        rescue 
           puts "ERROR: describe_load_balancer_policies #{$!}"
        end
     end
     return data
  end
  
  def describe_load_balancer_policy_types(type_names = [])
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
        begin 
	   response = conn.describe_load_balancer_policy_types(type_names)
           if response.status == 200 
              data = response.body['DescribeLoadBalancerPolicyTypesResult']['PolicyTypeDescriptions']
	   else
	      data = {}
           end
        rescue 
           puts "ERROR: describe_load_balancer_policy_types #{$!}"
        end
     end
     return data
  end
  
  def detach_load_balancer_from_subnets(subnet_ids, lb_name)
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.detach_load_balancer_from_subnets(subnet_ids, lb_name)
        if response.status == 200
           data = response.body['DetachLoadBalancerFromSubnetsResult']
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end
  end
  
  def disable_availability_zones_for_load_balancer(availability_zones, lb_name)
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.disable_availability_zones_for_load_balancer(availability_zones, lb_name)
        if response.status == 200
           data = response.body['DisableAvailabilityZonesForLoadBalancerResult']
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end
  end
  
  def enable_availability_zones_for_load_balancer(availability_zones, lb_name)
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.enable_availability_zones_for_load_balancer(availability_zones, lb_name)
        if response.status == 200
           data = response.body['EnableAvailabilityZonesForLoadBalancerResult']
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end 
  end
  
  def register_instances_with_load_balancer(instance_ids, lb_name)
     data = {}
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.register_instances_with_load_balancer(instance_ids, lb_name)
        if response.status == 200
           data = response.body['RegisterInstancesWithLoadBalancerResult']
	else
	   data = {}
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def set_load_balancer_listener_ssl_certificate(lb_name, load_balancer_port, ssl_certificate_id)
     data = false
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.set_load_balancer_listener_ssl_certificate(lb_name, load_balancer_port, ssl_certificate_id)
        if response.status == 200
           data = true
	else
	   data = false
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
  def set_load_balancer_policies_of_listener(lb_name, load_balancer_port, policy_names)
     data = false
     conn = @ec2_main.environment.elb_connection
     if conn != nil
	response = conn.set_load_balancer_policies_of_listener(lb_name, load_balancer_port, policy_names)
        if response.status == 200
           data = true
	else
	   data = false
        end 	    	   
     else 
        raise "Connection Error"
     end  
  end
  
end