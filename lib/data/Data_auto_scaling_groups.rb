require 'rubygems'

class Data_auto_scaling_groups

  def initialize(owner)
    puts "Data_auto_scaling_groups.initialize"
    @ec2_main = owner
  end
  def all
    data = Array.new
    conn = @ec2_main.environment.as_connection
    if conn != nil
      begin
        x = conn.groups.all
        x.each do |y|
          r= {}
          r[:auto_scaling_group_name] = y.id
          r[:launch_configuration_name] = y.launch_configuration_name
          r[:created_time] = y.created_at.to_s
          r[:min_size] = y.min_size
          r[:max_size] = y.max_size
          r[:desired_capacity] = y.desired_capacity
          r[:cooldown] = y.default_cooldown
          r[:load_balancer_names] = y.load_balancer_names
          # new fields
          r[:arn] = y.arn
          r[:enabled_metrics] = y.enabled_metrics
          r[:health_check_grace_period] = y.health_check_grace_period
          r[:health_check_type] = y.health_check_type
          r[:placement_group] = y.placement_group
          r[:suspended_processes] = y.suspended_processes
          r[:vpc_zone_identifier] = y.vpc_zone_identifier
          data.push(r)
        end
      rescue
        puts "ERROR: getting all auto_scaling_groups  #{$!}"
      end
    end
    return data
  end
  def get(id)
    r = {}
    conn = @ec2_main.environment.as_connection
    if conn != nil
      y = conn.groups.get(id)
      # test this.
      r= {}
      r[:auto_scaling_group_name] = y.id
      r[:launch_configuration_name] = y.launch_configuration_name
      r[:created_time] = y.created_at
      r[:min_size] = y.min_size
      r[:max_size] = y.max_size
      r[:desired_capacity] = y.desired_capacity
      r[:cooldown] = y.default_cooldown
      r[:instances] = y.instances
      r[:availability_zones] = y.availability_zones
      r[:load_balancer_names] = y.load_balancer_names
      # new fields
      r[:arn] = y.arn
      r[:enabled_metrics] = y.enabled_metrics
      r[:health_check_grace_period] = y.health_check_grace_period
      r[:health_check_type] = y.health_check_type
      r[:placement_group] = y.placement_group
      r[:suspended_processes] = y.suspended_processes
      r[:vpc_zone_identifier] = y.vpc_zone_identifier
      r[:tags] = y.tags
      return r
    else
      raise "Connection Error"
    end
    return r
  end
  def create_auto_scaling_group(auto_scaling_group_name, availability_zones, launch_configuration_name, max_size, min_size, options = {})
    data = false
    conn = @ec2_main.environment.as_connection
    if conn != nil
      data = conn.create_auto_scaling_group(auto_scaling_group_name, availability_zones, launch_configuration_name, max_size, min_size, options )
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
  def update_auto_scaling_group(auto_scaling_group_name, options = {})
    data = false
    conn = @ec2_main.environment.as_connection
    if conn != nil
      data = conn. update_auto_scaling_group(auto_scaling_group_name, options)
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
  def delete_auto_scaling_group(id, options = {})
    data = false
    conn = @ec2_main.environment.as_connection
    if conn != nil
      data = conn.delete_auto_scaling_group(id, options)
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
  def set_desired_capacity(auto_scaling_group_name, desired_capacity, options = {})
    data = false
    conn = @ec2_main.environment.as_connection
    if conn != nil
      response = conn.set_desired_capacity(auto_scaling_group_name, desired_capacity, options)
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
  def disable_metrics_collection(auto_scaling_group_name, options = {})
    data = false
    conn = @ec2_main.environment.as_connection
    if conn != nil
      response = conn.disable_metrics_collection(auto_scaling_group_name, options)
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
  def enable_metrics_collection(auto_scaling_group_name, granularity, options = {})
    data = false
    conn = @ec2_main.environment.as_connection
    if conn != nil
      response = conn.enable_metrics_collection(auto_scaling_group_name, granularity, options )
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

  def resume_processes(auto_scaling_group_name, options = {})
    data = false
    conn = @ec2_main.environment.as_connection
    if conn != nil
      response = conn.resume_processes(auto_scaling_group_name, options)
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
  def suspend_processes(auto_scaling_group_name, options = {})
    data = false
    conn = @ec2_main.environment.as_connection
    if conn != nil
      response = conn.suspend_processes(auto_scaling_group_name, options)
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
  def terminate_instance_in_auto_scaling_group(instance_id, should_decrement_desired_capacity)
    data = {}
    conn = @ec2_main.environment.as_connection
    if conn != nil
      data = conn.terminate_instance_in_auto_scaling_group(instance_id, should_decrement_desired_capacity)
      if data.status == 200
        data = data.body["TerminateGroupInAutoScalingInstanceResult"]
      else
        data = {}
      end
    else
      raise "Connection Error"
    end
    return data
  end

  def  put_notification_configuration(auto_scaling_group_name, notification_types, topic_arn)
    data = false
    conn = @ec2_main.environment.as_connection
    if conn != nil
      response = conn. put_notification_configuration(auto_scaling_group_name, notification_types, topic_arn)
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
  def delete_notification_configuration(auto_scaling_group_name, topic_arn)
    data = false
    conn = @ec2_main.environment.as_connection
    if conn != nil
      response = conn.delete_notification_configuration(auto_scaling_group_name, topic_arn)
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
end