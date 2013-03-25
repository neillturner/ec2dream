class Data_cfy_service
  def initialize(owner)
    @ec2_main = owner
  end

  def find_all_services()
    conn = @ec2_main.environment.connection 
    return [] if conn == nil  
    conn.list_services || []
  end

  def find(name)
    conn = @ec2_main.environment.connection 
    return nil if conn == nil  
    conn.service_info(name) || nil
  end

  def create(name, ss)
    conn = @ec2_main.environment.connection 
    return {} if conn == nil  
    conn.create_service(ss, name)
  end

  def delete(name)
    conn = @ec2_main.environment.connection 
    return {} if conn == nil  
    conn.delete_service(name)
  end
  
 def find_available_system_services
    available_system_services = []
    conn = @ec2_main.environment.connection 
    return {} if conn == nil  
    system_services = conn.cloud_services_info
    return {} if system_services == nil
    system_services.each do |service_type, service_value|
      service_value.each do |vendor, vendor_value|
        vendor_value.each do |version, service_info|
          available_system_services << [service_info[:vendor] + " " + service_info[:version], service_info[:vendor]]
        end
      end
    end
    available_system_services
  end 
  
end