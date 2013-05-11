require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fog'

class Data_addresses 

  def initialize(owner)
     puts "Data_addresses.initialize"
     @ec2_main = owner  
  end 
 
  # List elastic IPs by public addresses.
  #
  # Returns an array of 2 keys (:instance_id and :public_ip) hashes:
  # For OpenStack also returns internal id  (:id)
  #
  #  ec2.describe_addresses  #=> [{:instance_id=>"i-75ebd41b", :domain=>"standard", :public_ip=>"50.17.211.96"},
  #                                :domain=>"vpc", :public_ip=>"184.72.112.39",  :allocation_id=>"eipalloc-c6abfeaf"}]
  def all
      data = Array.new
      conn = @ec2_main.environment.connection
      if conn != nil
         begin
            if  @ec2_main.settings.openstack
               x = conn.addresses.all
               x.each do |y|
                  r = {}
                  r[:id] = y.id
                  #r[:pool]  = y.pool
                  if y.ip != nil 
                     r[:public_ip] =  y.ip
                  elsif y.fixed_ip != nil
                     r[:public_ip] = "#{r[:public_ip]}"
                  end   
                  r[:instance_id] = (y.instance_id).to_s
                  data.push(r)
               end
            elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
               x = conn.addresses.all
               x.each do |y|
                  r = {}
                  r[:public_ip] =  y.public_ip
                  if y.server_id != nil 
                     r[:instance_id] = y.server_id
                  end   
                  data.push(r)
               end            
            else            
               data = conn.describe_addresses
            end    
         rescue
            puts "ERROR: getting all Addresses  #{$!}"
         end
      end   
      return data
  end
 
 # not used
  def get(address_id) 
      data = {}
      conn = @ec2_main.environment.connection
      if conn != nil
         data = conn.get_address.get(address_id)
      else 
         raise "Connection Error"
      end
      return data
  end   
  
  # Associate an elastic IP address with an instance.
  # Options: :public_ip, :allocation_id.
  # Returns a hash of data or an exception.
  #
  #  ec2.associate_address('i-d630cbbf', :public_ip => '75.101.154.140') #=>
  #    { :return => true }
  #
  #  ec2.associate_address(inst, :allocation_id => "eipalloc-c6abfeaf") #=>
  #    { :return         => true,
  #      :association_id => 'eipassoc-fc5ca095'}
  #  
  def associate(server_id, ip_address, network_interface_id=nil, allocation_id=nil)
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
           data = conn.associate_address(server_id, ip_address)
	   if data.status == 202
	      data = true
	   else   
	      data = false
           end
        elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
           if allocation_id != nil and allocation_id != ""
                 data = conn.associate_address(server_id, ip_address, network_interface_id, allocation_id)
           else 
                data = conn.associate_address(server_id, ip_address)
           end
	   data = data.body
        else           
           data = conn.associate_address(server_id, {:public_ip=> ip_address})
        end   
     else 
        raise "Connection Error"
     end
     return data
  end 
  
  # Acquire a new elastic IP address for use with your account.
  # Returns allocated IP address or or an exception.
  #
  #  ec2.allocate_address #=>
  #    { :public_ip => "50.19.214.224",
  #      :domain    => "standard"}
  #
  def allocate(pool=nil)
       data = nil
       conn = @ec2_main.environment.connection
       if conn != nil
          if  @ec2_main.settings.amazon
             pool = "standard" if pool == nil 
             data = conn.allocate_address(pool) 
          elsif  !@ec2_main.settings.openstack
             data = conn.allocate_address({}) 
          else
             if pool == nil 
                data = conn.allocate_address
             else
                data = conn.allocate_address(pool)
             end 
             if data.status == 200
	        data = data.body["floating_ip"]
	     else   
	        data = nil
	     end   
          end            
       else 
          raise "Connection Error"
       end
       return data  
  end
  
  def list_addresses(address_id)
     data = nil
     conn = @ec2_main.environment.connection
     if conn != nil
        data = conn.list_addresses(address_id)
        if data.status == 200
  	   data = data.body["addresses"]
  	else   
  	   data = nil
        end            
     else 
        raise "Connection Error"
     end
     return data  
  end
  
  # Disassociate the specified elastic IP address from the instance to which it is assigned.
  # Options: :public_ip, :association_id.
  # Returns +true+ or an exception.
  # 
  #  ec2.disassociate_address(:public_ip => '75.101.154.140') #=> true
  #
  def disassociate(server_id, ip_address, association_id=nil)
     data = nil
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
           data = conn.disassociate_address(server_id.to_i, ip_address)
           if data.status == 202
              data = true
	   else   
	      data = nil
           end
        elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
           if association_id != nil 
              data = conn.disassociate_address(nil, association_id )
           else
              data = conn.disassociate_address(ip_address)
           end   
	   data = true
        else 	
           data = conn.disassociate_address({:public_ip=> ip_address})
        end   
    else 
        raise "Connection Error"
    end
     return data
  end 
 
  # Release an elastic IP address associated with your account.
  # Options: :public_ip, :allocation_id.
  # Returns +true+ or an exception.
  #
  #  ec2.release_address(:public_ip => '75.101.154.140') #=> true
  # 
  def release(address_id, allocation_id)
     data = nil
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
           id = nil
           all.each do |r|
              if r[:public_ip] == address_id
                id = r[:id]
              end
           end
           if id != nil 
              data = conn.release_address(id)
              if data.status == 200 or data.status == 202
  	         data = true
  	      else   
  	         data = nil
  	      end   
  	   else
  	      raise "Address Not Found" 
  	   end
        elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
           if allocation_id != nil 
              data = conn.release_address(allocation_id)
	      data = data.body           
           else
              data = conn.release_address(address_id)
	      data = data.body
	   end   
        end            
     else 
        raise "Connection Error"
     end
     return data  
  end  
  
  def add_fixed_ip(server_id, network_id)
     data = nil
     conn = @ec2_main.environment.connection
     if conn != nil
        data = conn.add_fixed_ip(server_id, network_id)
        if data.status == 200
  	   data = data.body["server_id"]
  	else   
  	   data = nil
        end
     else 
        raise "Connection Error"
     end
     return data
  end 
 
  def remove_fixed_ip(server_id, network_id)
     data = nil
     conn = @ec2_main.environment.connection
     if conn != nil
        data = conn.remove_fixed_ip(server_id, network_id)
        if data.status == 200
           data = data.body["removeFixedIp"]
  	else   
  	   data = nil
        end
     else 
        raise "Connection Error"
     end
     return data
  end 

end