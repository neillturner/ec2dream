require 'rubygems'

class Data_auto_scaling_instances

  def initialize(owner)
    puts "Data_auto_scaling_instances.initialize"
    @ec2_main = owner
  end
  def all
    data = Array.new
    conn = @ec2_main.environment.as_connection
    if conn != nil
      begin
        x = conn.instances.all
        x.each do |y|
          r= {}
          r[:instance_id] = y.id
          r[:health_status] = y.health_status
          r[:availability_zone] = y.availability_zone.
          r[:auto_scaling_group_name] = y.auto_scaling_group_name
          r[:launch_configuration_name] = y.launch_configuration_name
          r[:life_cycle_state] = y.life_cycle_state
          data.push(r)
        end
      rescue
        puts "ERROR: getting all auto_scaling_instances  #{$!}"
      end
    end
    return data
  end
end