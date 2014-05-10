require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fog'

class Data_servers

  def initialize(owner)
     puts "Data_servers.initialize"
     @ec2_main = owner
  end

  # Retrieve information about EC2 instances.
  #
  # Accepts a list of instances and/or a set of filters as the last parameter.
  #
  # Filters: architecture, availability-zone, block-device-mapping.attach-time, block-device-mapping.delete-on-termination,
  # block-device-mapping.device-name, block-device-mapping.status, block-device-mapping.volume-id, client-token, dns-name,
  # group-id, image-id, instance-id, instance-lifecycle, instance-state-code, instance-state-name, instance-type, ip-address,
  # kernel-id, key-name, launch-index, launch-time, monitoring-state, owner-id, placement-group-name, platform,
  # private-dns-name, private-ip-address, product-code, ramdisk-id, reason, requester-id, reservation-id, root-device-name,
  # root-device-type, spot-instance-request-id, state-reason-code, state-reason-message, subnet-id, tag-key, tag-value,
  # tag:key, virtualization-type, vpc-id,
  #
  #
  #  ec2.describe_instances #=>
  #    [{:source_dest_check=>true,
  #        :subnet_id=>"subnet-da6cf9b3",
  #        :aws_kernel_id=>"aki-3932d150",
  #        :ami_launch_index=>"0",
  #        :tags=>{},
  #        :aws_reservation_id=>"r-7cd25c11",
  #        :aws_owner=>"826693181925",
  #        :state_reason_code=>"Client.UserInitiatedShutdown",
  #        :aws_instance_id=>"i-2d898e41",
  #        :hypervisor=>"xen",
  #        :root_device_name=>"/dev/sda1",
  #        :aws_ramdisk_id=>"ari-c515f6ac",
  #        :aws_instance_type=>"m1.large",
  #        :groups=>[{:group_name=>"2009-07-15-default", :group_id=>"sg-90c5d6fc"}],
  #        :block_device_mappings=>
  #          [{:device_name=>"/dev/sda1",
  #            :ebs_status=>"attached",
  #            :ebs_attach_time=>"2011-03-04T18:51:58.000Z",
  #            :ebs_delete_on_termination=>true,
  #            :ebs_volume_id=>"vol-38f2bd50"}],
  #        :state_reason_message=>
  #          "Client.UserInitiatedShutdown: User initiated shutdown",
  #        :aws_image_id=>"ami-a3638cca",
  #        :virtualization_type=>"paravirtual",
  #        :aws_launch_time=>"2011-03-04T18:13:59.000Z",
  #        :private_dns_name=>"",
  #        :aws_product_codes=>[],
  #        :aws_availability_zone=>"us-east-1a",
  #        :aws_state_code=>80,
  #        :architecture=>"x86_64",
  #        :dns_name=>"",
  #        :client_token=>"1299262447-684266-NNgyH-ouPTI-MzG6h-5AIRk",
  #        :root_device_type=>"ebs",
  #        :vpc_id=>"vpc-e16cf988",
  #        :monitoring_state=>"disabled",
  #        :ssh_key_name=>"default",
  #        :private_ip_address=>"192.168.0.52",
  #        :aws_reason=>"User initiated ",
  #        :aws_state=>"stopped"}, ...]
  #
  def all(instance = [], filters = nil)
      data = []
      conn = @ec2_main.environment.connection
      if conn != nil
         #begin
         # need to handle instance parameter for openstack
            if  @ec2_main.settings.openstack
                x = conn.servers.all
                 x.each do |y|
                    r = {}
                   if @ec2_main.settings.openstack_hp
                      y.metadata.all.each do |m|
                        r[m.key]=m.value
                      end
                   else
                      m = y.metadata
                      if m != nil
		         m.each do |k,v|
		           r[k]=v
                         end
                      end
                   end
                   r[:id]= y.id
                   r[:addresses]= y.addresses
                   r[:host_id]= y.host_id
                   r[:metadata]= y.metadata
                   r[:name]= y.name
                   r['name']= y.name
                   r[:progress]= y.progress
                   r[:state] = y.state
                   r[:tenant_id] = y.tenant_id
		   r[:user_id] = y.user_id
                   #r[:min_count]= y.min_count
                   #r[:max_count]= y.max_count
                   r[:aws_instance_id] = y.id.to_s
                   r[:name] = y.name
                   # need to handle this in the list
                   #r[:tags]="name=#{y.instance_name},"tenant=#{y.tenant_id}"
       	 	   #r[:aws_launch_time] = nil
      	 	   if  !@ec2_main.settings.openstack_rackspace
      	 	      r[:key_name] = y.key_name
       	 	      r[:ssh_key_name] = y.key_name
      	 	   end
      	 	   r[:dns_name] = y.host_id
      	 	   r[:private_dns_name] = nil
      	 	   #r[:aws_availability_zone] = y.availability_zone
      	 	   r[:aws_state] = y.state
                   if  @ec2_main.settings.openstack_hp
                      r[:created_at]= y.created_at
                      r[:aws_launch_time]=y.created_at
                      r[:updated_at] = y.updated_at
                      if y.image.instance_of? Hash
                          r[:image_id] = y.image["id"]
                          r[:aws_image_id] = y.image["id"]
                       else
                         r[:aws_image_id] = y.image
                      end
                      r[:flavor] = y.flavor_id
                      r[:personality]= y.personality
                      r[:aws_instance_type] = y.flavor_id
                      r[:dns_name] = r[:public_ip_address]
                      r[:private_dns_name] = r[:private_ip_address]
                      r[:accessIPv4]= y.accessIPv4
                      r[:accessIPv6]= y.accessIPv6
                      r[:private_ip_address] = y.private_ip_address
                      r[:public_ip_address] = y.public_ip_address
                      r[:password] = y.password
                      r['security_groups']= y.security_groups

                      r[:aws_instance_type] = y.flavor_id
                   elsif  @ec2_main.settings.openstack_rackspace
                      r[:created_at]= y.created
                      r[:aws_launch_time]=y.created
                      r[:updated_at] = y.updated
                      r[:password] = y.password
                      r[:flavor] = y.flavor_id
                      r[:aws_instance_type] = y.flavor_id
                      r[:image]= y.image_id
		      y.addresses.each do |k, a|
                        #puts "k #{k} a #{a}"
                        a.each do |v|
                          #puts "v #{v}"
                          if v["addr"] != nil
                             if !v["addr"].start_with?("10.") and v["addr"].index(':')==nil
                                r[:dns_name] = v["addr"]
                                r[:public_ip] = v["addr"]
                             elsif v["addr"].start_with?("10.") and v["addr"].index(':')==nil
                                r[:private_dns_name] = v["addr"]
                             end
                          end
                        end
                      end
                      r[:accessIPv4]= y.ipv4_address
                      r[:accessIPv6]= y.ipv6_address
                      r[:public_ip_address] = y.ipv4_address
                      r['security_groups']= ["default"]
                      r[:aws_image_id] = y.image_id
                   else
                      r[:image]= y.image
                      r[:flavor]= y.flavor
                      r[:personality]= y.personality
                      r[:accessIPv4]= y.accessIPv4
                      r[:accessIPv6]= y.accessIPv6
                      r[:private_ip_address] = y.private_ip_address
                      r[:public_ip_address] = y.public_ip_address
                      r['security_groups'] = y.security_groups
                      r[:aws_image_id] = y.image
                      r[:aws_instance_type] = y.flavor
                   end
                   # rackspace should have an extra attribute :password
                   gp = Array.new
                   if  @ec2_main.settings.openstack_rackspace
		      gp.push('default')
                   else
                      gp.push('default')
                      #y.security_groups.each do |g|
                      #  gp.push(g['name'])
                      #end

                   end
                   r[:sec_groups]= gp
                   data.push(r)
                end
		      elsif @ec2_main.settings.google
					response = conn.list_servers($google_zone)
					if response.status == 200
						x = response.body['items']
						if x != nil
						  x.each do |r|
						    r[:aws_instance_id] = r['id'].to_s
						    r[:aws_state] = r['status']
						    data.push(r)
						  end
						end
					else
						data = []
					end
             elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
              if filters != nil
	         filter = filters
              else
                 filter = {}
              end
              filter['instance-id'] = instance if instance != []
              response = conn.describe_instances(filter)
	      if response.status == 200
	         data_s = response.body['reservationSet']
	         data = []
	         data_s.each do |rs|
	            gs=rs['groupSet']
	            rs['instancesSet'].each do |r|
	               r[:aws_instance_id] = r['instanceId']
                       r[:public_ip] = r['ipAddress']
                       r[:aws_state] = r['instanceState']['name']
                       r['groupSet']=rs['groupSet']
                       data.push(r)
                    end
	         end
	      else
	      	 data = {}
              end
               # x = conn.servers.all
               # x.each do |y|
               #    r = {}
              #     r[:aws_instance_id] 		= y.id
              #    r[:architecture] 		= y.architecture
               #    r[:ami_launch_index] 	= y.ami_launch_index
               #    r[:aws_availability_zone] 	= y.availability_zone
               #    r[:block_device_mappings] 	= y.block_device_mapping
        	# needs more processing
        	#  when %r{/blockDeviceMapping/item} # no trailing $
        	#    case name
        	#    when 'deviceName'          then @block_device_mapping[:device_name]                = @text
        	#    when 'virtualName'         then @block_device_mapping[:virtual_name]               = @text
        	#    when 'volumeId'            then @block_device_mapping[:ebs_volume_id]              = @text
        	#    when 'status'              then @block_device_mapping[:ebs_status]                 = @text
        	#    when 'attachTime'          then @block_device_mapping[:ebs_attach_time]            = @text
        	#    when 'deleteOnTermination' then @block_device_mapping[:ebs_delete_on_termination]  = @text == 'true' ? true : false
        	#    when 'item'                then @item[:block_device_mappings]                     << @block_device_mapping
        	#    end
                #   r[:network_interfaces]     	= y.network_interfaces
                 #  r[:client_token] 		= y.client_token
               #    r[:dns_name] 		= y.dns_name
               #    r[:groups] 			= y.groups
               #    r[:aws_instance_type] 	= y.flavor_id
               #    r[:aws_image_id] 		= y.image_id
               #    r[:aws_kernel_id] 		= y.kernel_id
               #    r[:ssh_key_name] 		= y.key_name
               #    r[:aws_launch_time] 		= y.created_at
               #    r[:monitoring_state]		= y.monitoring
               #    r[:aws_platform] 		= y.platform
               #    r[:aws_product_codes] 	= y.product_codes
               #    r[:dns_name] 		= y.private_dns_name
               #   r[:private_ip_address] 	= y.private_ip_address
               #    r[:ip_address] 		= y.public_ip_address
               #    r[:aws_ramdisk_id] 		= y.ramdisk_id
               #    r[:aws_reason] 		= y.reason
               #   r[:root_device_name] 	= y.root_device_name
               #    r[:root_device_type] 	= y.root_device_type
               #    r[:aws_state] 		= y.state
        	#  when %r{/instanceState/code$}  then @item[:aws_state_code]       = @text.to_i
        	#  when %r{/instanceState/name$}  then @item[:aws_state]            = @text
        	#   r[:state_reason_code] 	= y.state_reason
        	#  when %r{/stateReason/code$}    then @item[:state_reason_code]    = @text
        	#  when %r{/stateReason/message$} then @item[:state_reason_message] = @text
                #   r[:subnet_id] 		= y.subnet_id
                #   r[:placement_tenancy] 	= y.tenancy
        	#   r[:tags] = y.tags
        	#  when %r{/tagSet/item/key$}   then @aws_tag[:key]               = @text
        	#  when %r{/tagSet/item/value$} then @aws_tag[:value]             = @text
        	#  when %r{/tagSet/item$}       then @item[:tags][@aws_tag[:key]] = @aws_tag[:value]
                #   r[:vpc_id] 			= y.vpc_id
                #   data.push(r)
                #end
            else
                data = conn.describe_instances(instance,filters)
            end
         #rescue
         #   puts "ERROR: getting all servers  #{$!}"
         #end
      end
      return data
  end

  # not used
  def get(server_id)
      data = nil
      conn = @ec2_main.environment.connection
      if conn != nil
         data = conn.servers.get(server_id)
      else
         raise "Connection Error"
      end
      return data
  end

  # Launch new EC2 instances. Returns a list of launched instances or an exception.
  #
  #  ec2.run_instances('ami-e444444d',1,1,['2009-07-15-default'],'my_awesome_key', 'Woohoo!!!', 'public') #=>
  #   [{:aws_image_id       => "ami-e444444d",
  #     :aws_reason         => "",
  #     :aws_state_code     => "0",
  #     :aws_owner          => "000000000888",
  #     :aws_instance_id    => "i-123f1234",
  #     :aws_reservation_id => "r-aabbccdd",
  #     :aws_state          => "pending",
  #     :dns_name           => "",
  #     :ssh_key_name       => "my_awesome_key",
  #     :groups             => [{:group_name=>"2009-07-15-default", :group_id=>"sg-90c5d6fc"}],
  #     :private_dns_name   => "",
  #     :aws_instance_type  => "m1.small",
  #     :aws_launch_time    => "2008-1-1T00:00:00.000Z"
  #     :aws_ramdisk_id     => "ari-8605e0ef"
  #     :aws_kernel_id      => "aki-9905e0f0",
  #     :ami_launch_index   => "0",
  #     :aws_availability_zone => "us-east-1b"
  #     }]
  #
  def create_server(name, image_ref, flavor_ref, options = {})
      data = {}
      conn = @ec2_main.environment.connection
      if conn != nil
         if  @ec2_main.settings.openstack_rackspace
            puts "create server #{name}, #{image_ref.to_s}, #{flavor_ref.to_i}, #{options['min_count'].to_i}, #{options['max_count'].to_i}, "
            data = conn.create_server(name, image_ref.to_s, flavor_ref.to_i, options['min_count'].to_i, options['min_count'].to_i,{})
            if data.status == 200 or data.status == 202
	       data = data.body['server']
	       data[:sec_groups] = ['default']
	       puts "server create #{data}"
	       #data[:aws_instance_id] = data[:id].to_s
	       #data[:aws_launch_time] = data[:created].to_s
	    else
	       data = {}
	    end
         elsif  @ec2_main.settings.openstack_hp
            data = conn.create_server(name,  flavor_ref.to_i, image_ref.to_i, options)
            if data.status == 200 or data.status == 202
	       data = data.body['server']
	       data[:aws_instance_id] = data[:id].to_s
	       data[:aws_launch_time] = data[:created_at].to_s
	    else
	       data = {}
	    end
         elsif  @ec2_main.settings.openstack
            data = conn.create_server(name, image_ref.to_s, flavor_ref.to_i,  options)
            if data.status == 200 or data.status == 202
	       data = data.body['server']
	       data[:aws_instance_id] = data[:id].to_s
	       data[:aws_launch_time] = data[:created_at].to_s
	    else
	       data = {}
	    end
         elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
           min_count =  options['MinCount']
           max_count =  options['MaxCount']
           response = conn.run_instances(name, min_count, max_count, options)
            if response.status == 200
              data = []
 	      rs = response.body
	      gs=rs['groupSet']
	      rs['instancesSet'].each do |r|
	         r[:aws_instance_id] = r['instanceId']
                 r[:public_ip] = r['ipAddress']
                 r[:aws_state] = r['instanceState']['name']
                 r['groupSet'] = gs
                 data.push(r)
             end
           else
              data = []
           end
         else
            data = conn.launch_instances(name, options)
         end
      else
         raise "Connection Error"
      end
      return data
  end

  def request_spot_instances(options)
     data = []
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
        # openstack
        elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
           image_id = options['LaunchSpecification.ImageId']
           instance_type = options['LaunchSpecification.InstanceType']
           spot_price = options['SpotPrice']
           response = conn.request_spot_instances(image_id, instance_type, spot_price, options)
           if response.status == 200
              data = response.body['spotInstanceRequestSet']
           else
              data = []
           end
        else
           data = conn.request_spot_instances(options)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Terminates EC2 instances. Returns a list of termination params or an exception.
  #
  #  ec2.terminate_instances(['i-cceb49a4']) #=>
  #    [{:aws_instance_id=>"i-cceb49a4",
  #      :aws_current_state_code=>32,
  #      :aws_current_state_name=>"shutting-down",
  #      :aws_prev_state_code=>16,
  #      :aws_prev_state_name=>"running"}]
  #

  def delete_server(server_id, zone_name=nil)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        if @ec2_main.settings.openstack
           #if  !@ec2_main.settings.openstack_rackspace
           #   data = conn.delete_server(server_id.to_i)
           #else
              data = conn.delete_server(server_id)
           #end
           if data.status == 204
	          data = true
	       else
	          data = false
	       end
		elsif @ec2_main.settings.google
		   response = conn.delete_server(server_id, zone_name)
           if response.status == 200
              data = response.body
           else
              data = {}
           end
        else
            data = conn.terminate_instances([server_id])
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Stop instances.
  #
  # Options: :force => true|false
  #
  #  ec2.stop_instances("i-36e84a5e") #=>
  #    [{:aws_prev_state_code=>16,
  #      :aws_prev_state_name=>"running",
  #      :aws_instance_id=>"i-36e84a5e",
  #      :aws_current_state_code=>64,
  #      :aws_current_state_name=>"stopping"}]
  #
  def stop_instances(server_id)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
           data = conn.pause_server(server_id)
        elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
           data = conn.stop_instances([server_id])
        else
           data = conn.stop_instances(server_id)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Start instances.
  #
  #  ec2.start_instances("i-36e84a5e") #=>
  #    [{:aws_prev_state_name=>"stopped",
  #      :aws_instance_id=>"i-36e84a5e",
  #      :aws_current_state_code=>16,
  #      :aws_current_state_name=>"running",
  #      :aws_prev_state_code=>80}]
  #
  def start_instances(server_id)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
           data = conn.resume_server(server_id)
        elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
           data = conn.start_instances([server_id])
        else
           data = conn.start_instances(server_id)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  def reboot_server(server_id,type)
       data = {}
       conn = @ec2_main.environment.connection
       if conn != nil
          if  @ec2_main.settings.openstack_rackspace
             data = conn.reboot_server(server_id, type)
          elsif @ec2_main.settings.openstack
             data = conn.reboot_server(server_id.to_i,type)
          else
             # amazon
          end
       else
          raise "Connection Error"
       end
       return data
  end

  def change_password_server(server_id, admin_password)
       data = {}
       conn = @ec2_main.environment.connection
       if conn != nil
          if  @ec2_main.settings.openstack_rackspace
             data = conn.change_server_password(server_id, admin_password)
          elsif  @ec2_main.settings.openstack
             data = conn.change_password_server(server_id.to_i, admin_password)
          else
             # amazon
          end
       else
          raise "Connection Error"
       end
       return data
  end

  # Get initial Windows Server setup password from an instance console output.
  #
  #  # wait until instance enters 'operational' state and get it's initial password
  #
  #  puts ec2.get_initial_password(my_awesome_instance[:aws_instance_id], my_awesome_key[:aws_material]) #=> "MhjWcgZuY6"
  #
  def get_initial_password(instance, pk_text)
     data = ""
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
        # openstack
        ##elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
        #   data = conn.get_password_data(instance)
        #   data  = data['passwordData']
        elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
           response = conn.get_password_data(instance)
           puts "ERROR: status #{response.status} response #{response.body}"
           puts "ERROR: there is fog bug getting windows admin password"
           if response.status = 200
              data = response.body['passwordData']
           end
        else
           data = conn.get_initial_password(instance, pk_text)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Retreive EC2 instance OS logs. Returns a hash of data or an exception.
  #
  #  ec2.get_console_output('i-f222222d') =>
  #    {:aws_instance_id => 'i-f222222d',
  #     :aws_timestamp   => "2007-05-23T14:36:07.000-07:00",
  #     :timestamp       => Wed May 23 21:36:07 UTC 2007,          # Time instance
  #     :aws_output      => "Linux version 2.6.16-xenU (builder@patchbat.amazonsa) (gcc version 4.0.1 20050727 ..."
  def get_console_output(instance, num_lines=1000)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
           response = conn.get_console_output(instance, num_lines)
           if response.status = 200
              data[:aws_output] = response.body['output']
           end
        elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
           response = conn.get_console_output(instance)
           if response.status = 200
              data[:aws_output] = response.body['output']
           end
        else
           data = conn.get_console_output(instance)
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Enables monitoring for a running instances. For more information, refer to the Amazon CloudWatch Developer Guide.
  #
  #  ec2.monitor_instances('i-8437ddec') #=>
  #    {:instance_id=>"i-8437ddec", :monitoring_state=>"pending"}
  #
  def monitor_instances(instance)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
        # openstack
        else
           data = conn.monitor_instances([instance])
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Disables monitoring for a running instances. For more information, refer to the Amazon CloudWatch Developer Guide.
  #
  #  ec2.unmonitor_instances('i-8437ddec') #=>
  #    {:instance_id=>"i-8437ddec", :monitoring_state=>"disabling"}
  #
  def unmonitor_instances(instance)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
        # openstack
        else
           data = conn.unmonitor_instances([instance])
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Modify instance attribute.
  #
  # Attributes: 'InstanceType', 'Kernel', 'Ramdisk', 'UserData', 'DisableApiTermination',
  # 'InstanceInitiatedShutdownBehavior', 'SourceDestCheck', 'GroupId'
  #
  #  ec2.modify_instance_attribute(instance, 'instanceInitiatedShutdownBehavior", "stop") #=> true
  #
  def modify_instance_attribute(instance,attr,value)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
        # openstack
        else
           data = conn.modify_instance_attribute(instance,{ attr => value})
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Describe instance attribute.
  #
  # Attributes: 'instanceType', 'kernel', 'ramdisk', 'userData', 'rootDeviceName', 'disableApiTermination',
  # 'instanceInitiatedShutdownBehavior', 'sourceDestCheck', 'blockDeviceMapping', 'groupSet'
  #
  #  ec2.describe_instance_attribute(instance, "blockDeviceMapping") #=>
  #     [{:ebs_delete_on_termination=>true,
  #       :ebs_volume_id=>"vol-683dc401",
  #       :device_name=>"/dev/sda1"}]
  #
  #  ec2.describe_instance_attribute(instance, "instanceType") #=> "m1.small"
  #
  #  ec2.describe_instance_attribute(instance, "instanceInitiatedShutdownBehavior") #=> "stop"
  #
  def describe_instance_attribute(instance,attr)
     data = ""
     conn = @ec2_main.environment.connection
     if conn != nil
        if  @ec2_main.settings.openstack
        # openstack
           data = conn.describe_instance_attribute(instance,attr)
        else
           data = ""
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Get the current google project
  def  get_project
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.get_project
        if response.status == 200
           data = response.body
        else
           data = {}
        end
     else
        raise "Connection Error"
     end
     return data
  end


  # set google  instance tags
  def set_tags(instance, zone, tags=[])
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.set_tags(instance, zone, tags)
        if response.status == 200
           data = response.body
        else
           data = {}
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Insert a google common instance metadata
  def  set_common_instance_metadata(metadata={})
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.set_common_instance_metadata(metadata)
        if response.status == 200
           data = response.body
        else
           data = {}
        end
     else
        raise "Connection Error"
     end
     return data
  end

   # Insert a google server metadata
  def  set_meta(server_name, zone_name, metadata={})
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.set_metadata(server_name, zone_name, metadata)
        if response.status == 200
           data = response.body
        else
           data = {}
        end
     else
        raise "Connection Error"
     end
     return data
  end

# Get a google server
  def  get_server(name, zone_name=nil)
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
	    puts "*** get_server name #{name} zone_name #{zone_name}"
        response = conn.get_server(name, zone_name)
		puts "*** status #{response.status}"
		puts "*** body #{response.body}"
        if response.status == 200
           data = response.body
        else
           data = {}
        end
     else
        raise "Connection Error"
     end
     return data
  end



   # Insert a google server
  def  insert_server(server_name, zone_name, options={})
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.insert_server(server_name, zone_name, options)
        if response.status == 200
           data = response.body
        else
           data = {}
        end
     else
        raise "Connection Error"
     end
     return data
  end

  # Delete a google zone operation
  def  delete_zone_operation(zone, operation_name)
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.delete_zone_operation(zone, operation_name)
        if response.status == 200
           data = response.body
        else
           data = {}
        end
     else
        raise "Connection Error"
     end
     return data
  end

 # Delete a google global operation
  def  delete_global_operation(operation_name)
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.delete_global_operation(operation_name)
        if response.status == 200
           data = response.body
        else
           data = {}
        end
     else
        raise "Connection Error"
     end
     return data
  end


 end