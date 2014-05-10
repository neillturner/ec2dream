class EC2_Server

#
#  ops methods
#

  def ops_clear_panel
       @type = ""
       ops_clear('Instance_ID')
       ENV['EC2_INSTANCE'] = ""
       ops_clear('Name')
       ops_clear('Chef_Node')
       ops_clear('Security_Groups')
       ops_clear('Image_ID')
       ops_clear('State')
       ops_clear('Addresses')
       ops_clear('Public_Addr')
       ops_clear('Progress')
       ops_clear('Personality')
       ops_clear('Flavor')
       ops_clear('Availability_Zone')
       ops_clear('Launch_Time')
       ops_clear('Key_Name')
       if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
          ops_clear('SSH_Private_Key')
       else
          ops_clear('Putty_Private_Key')
       end
       ops_clear('EC2_SSH_User')
       @frame1.hide()
       @page1.width=300
       @frame4.hide()
	   @frame5.hide()
       @frame6.hide()
	   @frame7.hide()
       @frame3.show()
       @server_status = ""
       @secgrp = ""
  end

  def ops_clear(key)
    @ops_server[key].text = ""
  end

  def ops_load(instance_id)
      puts "server.ops_load "+instance_id
      @type = "ops"
      @frame1.hide()
      @page1.width=300
      @frame4.hide()
	  @frame5.hide()
      @frame6.hide()
	  @frame7.hide()
      @frame3.show()
      @ops_server['Instance_ID'].text = instance_id
      ENV['EC2_INSTANCE'] = instance_id
      #puts "instance id #{instance_id}"
      r = @ec2_main.serverCache.instance(instance_id)
      if r != nil
     	 gp = group_array(r)
         gp_list = ""
         gp_first = ""
         gp.each do |g|
            if gp_list.length>0
               gp_list = gp_list+","+g
            else
               gp_first = g
               gp_list = g
            end
         end
    	 @ops_server['Security_Groups'].text = gp_list
    	 @secgrp = gp_first
    	 if r[:name] == nil
    	   return
    	 end
    	 @ops_server['Name'].text = r[:name]
    	 @ops_server['Chef_Node'].text = ops_get_chef_node
    	 @ops_server['Image_ID'].text = r[:aws_image_id]['id']
    	 @ops_server['State'].text = r[:aws_state]
    	 @server_status = @ops_server['State'].text
    	 @ops_server['Launch_Time'].text = convert_time(r[:aws_launch_time])
    	 @ops_server['Key_Name'].text = ""
    	 if r[:key_name] != nil
    	    @ops_server['Key_Name'].text =  r[:key_name]
    	 end
     	 #if @windows_admin_pw[instance_id] != nil and @windows_admin_pw[instance_id] != ""
    	 #  @server['Win_Admin_Password'].text = @windows_admin_pw[instance_id]
    	 #else
    	 #  if @ec2_main.launch.get('Security_Group') ==  @server['Security_Groups'].text
    	 #     @server['Win_Admin_Password'].text = @ec2_main.launch.get('Win_Admin_Password')
    	 #  else
    	 #      @server['Win_Admin_Password'].text = ""
    	 #  end
    	 #end
     	 if @ops_public_addr[instance_id] != nil and @ops_public_addr[instance_id] != ""
    	   @ops_server['Public_Addr'].text = @ops_public_addr[instance_id]
    	 elsif @ec2_main.launch.ops_get('Public_Addr') != nil
    	    @ops_server['Public_Addr'].text = @ec2_main.launch.ops_get('Public_Addr')
    	 else
    	    @ops_server['Public_Addr'].text = ""
    	 end
    	 @ops_server['Addresses'].text = ""
    	 addr_list = ""
    	 r[:addresses].each do |k, a|
    	    #puts "*** k #{k} a #{a}"
    	    a.each do |v|
    	       #puts "*** v #{v}"
    	       if v["addr"] != nil
    	          if addr_list.length > 0
    	             addr_list = addr_list+","+v["addr"]
    	          else
    	             addr_list = v["addr"]
                  end
                  if v["OS-EXT-IPS:type"] == 'floating'
                     @ops_server['Public_Addr'].text = v["addr"]
                     @ops_public_addr[instance_id] = v["addr"]
                  end
               end
             end
         end
         if @ops_server['Public_Addr'].text ==nil or @ops_server['Public_Addr'].text == ""
            v = addr_list.split(',')
            if v.size>0
              @ops_server['Public_Addr'].text  = v[-1]
              @ops_public_addr[instance_id]  = v[-1]
            end
         end
         @ops_server['Addresses'].text = addr_list
    	 @ops_server['Progress'].text = "#{r[:progress]}%"
    	 #if r.personality != nil
    	 #   @ops_server['Personality'].text = r.personality
    	 #else
    	 #   @ops_server['Personality'].text = ""
    	 #end
    	 if  @ec2_main.settings.openstack_rackspace
    	    @ops_server['Flavor'].text = r[:flavor]
    	 else
    	    @ops_server['Flavor'].text = r[:flavor]["id"]
    	 end
    	 if r[:availability_zone] != nil
    	    @ops_server['Availability_Zone'].text = r[:availability_zone]
    	 else
    	    @ops_server['Availability_Zone'].text =  ""
    	 end
    	 if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
            @ops_server['EC2_SSH_Private_Key'].text = get_pk
         else
            @ops_server['Putty_Private_Key'].text = get_ppk
         end
         @ops_server['EC2_SSH_User'].text = ""
         #instance_id = @ops_server['Instance_ID'].text
         ssh_u = @ec2_main.launch.ops_get('EC2_SSH_User')
         if ssh_u != nil and ssh_u != ""
            @ops_server['EC2_SSH_User'].text = ssh_u
         end
       	 if @ops_admin_pw[instance_id] != nil and @ops_admin_pw[instance_id] != ""
    	   @ops_server['Admin_Password'].text = @ops_admin_pw[instance_id]
    	 else
      	   if @ec2_main.launch.ops_get('Security_Group') == @secgrp
    	      @ops_server['Admin_Password'].text = @ec2_main.launch.ops_get('Admin_Password')
    	   else
    	       @ops_server['Admin_Password'].text = ""
    	   end
    	 end
    	 if r[:password] != nil
	    @ops_server['Admin_Password'].text =  r[:password]
	 end
     else
	ops_clear_panel
     end
     @ec2_main.app.forceRefresh
  end

def group_array(x)
     ga = Array.new
     #puts "security groups #{x['security_groups']}"
     if x[:sec_groups].instance_of? Array and x[:sec_groups][0] != nil
        ga = x[:sec_groups]
     elsif x['security_groups'].instance_of? Array and x['security_groups'][0] != nil
        x['security_groups'].each do |g|
         ga.push(g['name'])
        end
     elsif x[:groups].instance_of? Array and x[:groups][0][:group_name] == nil
        x[:groups].each do |g|
         ga.push(g['group_id'])
        end
     else
        x[:groups].each do |g|
         ga.push(g['group_name'])
        end
     end
     return ga
 end


 def ops_terminate
   instance = @ops_server['Instance_ID'].text
   answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Termination","Confirm Termination of Server Instance "+instance)
   if answer == MBOX_CLICKED_YES
       begin
          r = @ec2_main.environment.servers.delete_server(instance)
       rescue
          error_message("Terminate Instance Failed",$!)
       end
   end
 end

  def ops_get_chef_node
       instance_id = @ops_server['Instance_ID'].text
       if @ec2_chef_node[instance_id] != nil and @ec2_chef_node[instance_id] != ""
   	cn =  @ec2_chef_node[instance_id]
       else
         cn = @ec2_main.launch.get('Chef_Node')
         if cn == nil or cn == ""
          cn = @ops_server['Name'].text
         end
       end
       return cn
  end



end