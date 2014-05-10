require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fog'

class Data_security_group

  def initialize(owner)
     puts "data_security_group.initialize"
     @ec2_main = owner
  end

  # Retrieve Security Groups information.
  #
  #  # Amazon cloud:
  #  ec2 = Rightscale::Ec2.new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
  #  ec2.describe_security_groups #=>
  #    [{:aws_perms=>
  #        [{:protocol=>"-1", :cidr_ips=>"0.0.0.0/0", :direction=>:egress},
  #        {:protocol=>"tcp",
  #          :cidr_ips=>"127.0.0.2/32",
  #          :direction=>:egress,
  #          :from_port=>"1111",
  #          :to_port=>"1111"},
  #        {:protocol=>"tcp",
  #          :cidr_ips=>"127.0.0.1/32",
  #          :direction=>:egress,
  #          :from_port=>"1111",
  #          :to_port=>"1111"}],
  #      :aws_group_name=>"kd-vpc-egress-test-1",
  #      :vpc_id=>"vpc-e16cf988",
  #      :aws_description=>"vpc test",
  #      :aws_owner=>"826693181925",
  #      :group_id=>"sg-b72032db"}]
  #
    def all(filter=nil)
      data = []
      conn = @ec2_main.environment.connection
      if conn != nil
         begin
           if  @ec2_main.settings.openstack_rackspace or @ec2_main.settings.google
		 r = {}
                 r[:id] = 1000
                 r[:name] = 'default'
                 r[:aws_group_name] = 'default'
                 r[:description] = 'dummy default security group'
                 data.push(r)
           elsif  @ec2_main.settings.openstack
              x = conn.security_groups.all
              x.each do |y|
                 r = {}
                 r[:id] = y.id
                 r[:group_id] = y.id
                 r[:name] = y.name
                 r[:aws_group_name] = y.name
                 r[:description] = y.description
                 r[:rules] = y.security_group_rules
                 r[:tenant_id] = y.tenant_id
                 data.push(r)
              end
			elsif @ec2_main.settings.google
             response = conn.list_firewalls
		     if response.status == 200
	             data = response.body['items']
             else
	      	     data = []
              end
            elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
              if filter != nil
                  response = conn.describe_security_groups(filter)
              else
                 response = conn.describe_security_groups
              end
	      if response.status == 200
	         data = response.body['securityGroupInfo']
	         data.each do |r|
			r[:id] = r['groupId']
                 	r[:name] = r['groupName'].to_s
                 	r[:aws_group_name] = r['groupName'].to_s
                 	r[:aws_description] = r['groupDescription']
                 	r[:group_id] = r['groupId']
                 	r[:owner_id] = r['ownerId']
                 	r[:vpc_id] = r['vpcId']
	         end
	      else
	      	 data = []
              end
            else
              data = conn.describe_security_groups
           end
         rescue
            puts "ERROR: getting all security groups #{$!}"
         end
      end
      return data
  end

  def get(security_group_id)
     data = {}
     conn = @ec2_main.environment.connection
     if conn != nil
       data = conn.security_groups.get(security_group_id)
       puts "*** sec_grp #{security_group_id} #{data}"
     else
       raise "Connection Error"
     end
     return data
  end

  # Create new Security Group. Returns +true+ or an exception.
  # Options: :vpc_id
  #
  #  ec2.create_security_group('default-1',"Default allowing SSH, HTTP, and HTTPS ingress") #=>
  #    { :group_id=>"sg-f0227599", :return=>true }
  #
  def create(sec_group,desc,vpc_id=nil)
       data = nil
       conn = @ec2_main.environment.connection
       if conn != nil
          if  @ec2_main.settings.openstack
             data = conn.create_security_group(sec_group, desc)
             if data.status == 200
	        data = data.body["security_group"]
	     else
	        data = nil
	     end
	  elsif  @ec2_main.settings.amazon
	     response = conn.create_security_group(sec_group, desc,vpc_id)
	     data = response.body
          else
             data = conn.create_security_group(sec_group,desc)
          end
       else
         raise "Connection Error"
       end
       return data
  end

  # Add permission to a security group. Returns +true+ or an exception. +protocol+ is one of :'tcp'|'udp'|'icmp'.
  #
  #  ec2.authorize_security_group_IP_ingress('my_awesome_group', 80, 82, 'udp', '192.168.1.0/8') #=> true
  #  ec2.authorize_security_group_IP_ingress('my_awesome_group', -1, -1, 'icmp') #=> true
  #
  def create_security_group_rule(parent_group_id, ip_protocol, from_port, to_port, cidr, group_id=nil, group_name=nil, group_auth=nil, group_auth_id=nil )

     puts "Data_security_group.create_security_group_rule( #{parent_group_id}, #{ip_protocol}, #{from_port}, #{to_port}, #{cidr}, #{group_id}, #{group_name}, #{group_auth}, #{group_auth_id})"
      # group_id field not necessary
       data = nil
       conn = @ec2_main.environment.connection
       if conn != nil
          if  @ec2_main.settings.openstack
               parent_group_id = group_id if group_id != nil
               data = conn.create_security_group_rule(parent_group_id, ip_protocol, from_port, to_port, cidr, nil)
             if data.status == 200
	        data = data.body["security_group_rule"]
	     else
	        data = nil
	     end
	  elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
	      opt = {}
	      opt['Groups']=[{'GroupId' => group_auth_id}] if group_auth_id!=nil
	      opt['Groups']=[{'GroupName' => group_auth}] if group_auth!=nil and group_auth_id==nil
	      opt['IpProtocol']=ip_protocol
	      opt['FromPort']=from_port.to_i
	      opt['ToPort']=to_port.to_i
	      opt['IpRanges']=[{'CidrIp' => cidr}] if cidr!=nil and cidr!=""
	      options = {}
	      options['IpPermissions']=[opt]
	      if group_id != nil and group_id != "0"
	        options['GroupId']= group_id
	        group_name = nil
	      else
		options = {}
	        options['IpProtocol']=ip_protocol
	        options['FromPort']=from_port.to_i
	        options['ToPort']=to_port.to_i
	        options['CidrIp']=cidr  if cidr!=nil and cidr!=""
	      end
	      data = conn.authorize_security_group_ingress(group_name, options)
          else
              data = conn.authorize_security_group_IP_ingress(group_name, from_port, to_port, ip_protocol, cidr)
          end
       else
         raise "Connection Error"
       end
       return data
  end

  # Authorize named ingress for security group. Allows instances that are member of someone
  # else's security group to open connections to instances in my group.
  #
  #  ec2.authorize_security_group_named_ingress('my_awesome_group', '7011-0219-8268', 'their_group_name') #=> true
  #
  def authorize_security_group_named_ingress(current_group, id ,group, current_group_id=nil, group_id=nil)
         data = nil
         conn = @ec2_main.environment.connection
         if conn != nil
            if  @ec2_main.settings.openstack
             response = conn.create_security_group_rule( current_group_id, nil, nil, nil, nil, group_id)
             if response.status == 200
	        data = response.body["security_group_rule"]
	     else
	        data = nil
	     end
	    elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
	      options = {}
              options['IpProtocol']='tcp'
              options['SourceSecurityGroupName']= group
	      data = conn.authorize_security_group_ingress(current_group, options)
            else
                data = conn.authorize_security_group_named_ingress(current_group, id ,group)
            end
         else
           raise "Connection Error"
         end
         return data
  end

  # Remove permission from a security group. Returns +true+ or an exception. +protocol+ is one of :'tcp'|'udp'|'icmp' ('tcp' is default).
  #
  #  ec2.revoke_security_group_IP_ingress('my_awesome_group', 80, 82, 'udp', '192.168.1.0/8') #=> true
  #
  def delete_security_group_rule(sec_group, protocol, from_port, to_port, ip_address, rule_id=nil, group_auth=nil, group_id=nil, group_auth_id=nil)
       data = nil
       conn = @ec2_main.environment.connection
       if conn != nil
          if  @ec2_main.settings.openstack
             data = conn.delete_security_group_rule(rule_id)
          elsif ((conn.class).to_s).start_with? "Fog::Compute::AWS"
 	      opt = {}
 	      opt['Groups']=[{'GroupId' => group_auth_id}] if group_auth_id!=nil
	      opt['Groups']=[{'GroupName' => group_auth}] if group_auth!=nil and group_auth_id==nil
 	      opt['IpProtocol']=protocol
	      opt['FromPort']=from_port.to_i
	      opt['ToPort']=to_port.to_i
	      opt['IpRanges']=[{'CidrIp' => ip_address}] if ip_address!=nil and ip_address!=""
	      options = {}
	      options['IpPermissions']=[opt]
              if group_id != nil and group_id != "0"
	        options['GroupId']= group_id
	        sec_group = nil
	      end
              data = conn.revoke_security_group_ingress(sec_group, options)
          else
             data = conn.revoke_security_group_IP_ingress(sec_group, from_port, to_port, protocol, ip_address)
          end
       else
         raise "Connection Error"
       end
       return data
  end

  # Revoke named ingress for security group.
  #
  #  ec2.revoke_security_group_named_ingress('my_awesome_group', aws_user_id, 'another_group_name') #=> true
  #
  def revoke_security_group_named_ingress(sec_group, id ,group, rule_id=nil)
           data = nil
           conn = @ec2_main.environment.connection
           if conn != nil
              if  @ec2_main.settings.openstack
                  data = conn.delete_security_group_rule(rule_id)
               else
                  data = conn.revoke_security_group_named_ingress(sec_group, id ,group)
              end
           else
             raise "Connection Error"
           end
           return data
  end

  # Remove Security Group. Returns +true+ or an exception.
  # Options: :group_name, :group_id
  #
  #  # Delete security group by group_id:
  #  ec2.delete_security_group('sg-90054ef9') #=> true
  #  ec2.delete_security_group(:group_id => 'sg-90054ef9') #=> true
  #
  #  # Delete security group by name (EC2 only):
  #  ec2.delete_security_group(:group_name => 'my-group']) #=> true
  #
  def delete(group_id, group_name=nil)
       response = false
       conn = @ec2_main.environment.connection
       if conn != nil
          if  @ec2_main.settings.openstack
             data = conn.delete_security_group(group_id.to_i)
          elsif @ec2_main.settings.get("EC2_PLATFORM") == "amazon"
	         data = conn.delete_security_group(nil, group_id)
	      else
	         data = conn.delete_security_group(group_name, nil)
          end
          response = true
       else
          raise "Connection Error"
       end
       return response
  end

  # Delete a google firewall
  def  delete_firewall(name)
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.delete_firewall(name)
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

   # Insert a google firewall
  def  insert_firewall(name, source_range, source_tags, allowed, network=nil)
     data = false
     conn = @ec2_main.environment.connection
     if conn != nil
        response = conn.insert_firewall(name, source_range, source_tags, allowed, network)
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