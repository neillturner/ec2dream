class EC2_Server

#
#  google methods
#
 
  def google_clear_panel
       @type = ""
       google_clear('Instance_ID')
       ENV['EC2_INSTANCE'] = ""
       google_clear('Name')
       google_clear('Chef_Node')
       google_clear('State')
	   @google_server['Addresses'].setVisibleRows(5)
       @google_server['Addresses'].setText("") 	   
       google_clear('Public_Addr')
 	   google_clear('Can_Ip_Forward')
       google_clear('Tags')
       google_clear('Kernel')
       google_clear('Flavor')
       google_clear('Availability_Zone')
	   google_clear('Scheduling')
	   @google_server['Disks'].setVisibleRows(5)
       @google_server['Disks'].setText("") 	   	   
       google_clear('Launch_Time')
       if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
          google_clear('SSH_Private_Key')
       else
          google_clear('Putty_Private_Key')
       end
       google_clear('EC2_SSH_User')
	   @google_server['Metadata'].setVisibleRows(5)
       @google_server['Metadata'].setText("") 
       @frame1.hide()
       @page1.width=300
       @frame4.hide()
	   @frame5.hide()	   
       @frame3.hide()
	   @frame6.show()
       @server_status = ""
       @secgrp = ""
  end 
     
  def google_clear(key)
    @google_server[key].text = ""
  end 
 
  def google_load(instance_id)
      puts "server.google_load "+instance_id
      @type = "google"
      @frame1.hide()
      @page1.width=300
      @frame4.hide()
	  @frame5.hide()	  
      @frame3.hide()
	  @frame6.show()
      @google_server['Instance_ID'].text = instance_id
      ENV['EC2_INSTANCE'] = instance_id
      #puts "instance id #{instance_id}"
      r = @ec2_main.serverCache.instance(instance_id)
	  if r == nil
        r = @ec2_main.environment.servers.get_server(instance_id,$google_zone)	  
	  end
	  puts "*** server #{r}"
      if r != nil	 
    	 if r['name'] == nil 
    	   return
    	 end  
    	 @google_server['Name'].text = r['name']
    	 @google_server['Chef_Node'].text = google_get_chef_node
     	 @google_server['State'].text = r['status']
    	 @server_status = @google_server['State'].text
    	 @google_server['Launch_Time'].text = convert_time(r['creationTimestamp'])
		 @google_server['Can_Ip_Forward'].text =r['canIpForward'].to_s
		 @google_server['Tags'].text = ""
		 @google_server['Tags'].text =r['tags']['items'].to_s if r['tags']['items'] != nil 
		 @google_server['Kernel'].text =google_last(r['kernel'])
	     @google_server['Metadata'].setText(r['metadata'].to_s) 
    	 #@google_server['Key_Name'].text = ""
    	 #if r[:key_name] != nil
    	 #   @google_server['Key_Name'].text =  r[:key_name]
    	 #end
     	 #if @windows_admin_pw[instance_id] != nil and @windows_admin_pw[instance_id] != ""
    	 #  @server['Win_Admin_Password'].text = @windows_admin_pw[instance_id]
    	 #else
    	 #  if @ec2_main.launch.get('Security_Group') ==  @server['Security_Groups'].text
    	 #     @server['Win_Admin_Password'].text = @ec2_main.launch.get('Win_Admin_Password')
    	 #  else
    	 #      @server['Win_Admin_Password'].text = ""
    	 #  end
    	 #end    	 
     	#if @google_public_addr[instance_id] != nil and @google_public_addr[instance_id] != ""
    	#   @google_server['Public_Addr'].text = @google_public_addr[instance_id]
    	# elsif @ec2_main.launch.google_get('Public_Addr') != nil 
    	#    @google_server['Public_Addr'].text = @ec2_main.launch.google_get('Public_Addr')
    	# else   
    	#    @google_server['Public_Addr'].text = ""
    	# end   
    	 addr_list = ""
    	 r['networkInterfaces'].each do | a|
    	    #puts "a #{a}"
			n = a["name"]
			ip = a["networkIP"]
            type = []
			nat_ip = []
			if a['accessConfigs'] != nil 
               a['accessConfigs'].each do |c|
                 if c['natIP']!=nil and  c['natIP'] != ""
                   nat_ip.push(c['natIP'])
				   if @google_server['Public_Addr'].text == ""
                      @google_server['Public_Addr'].text = c['natIP']
                      @google_public_addr[instance_id] = c['natIP']  
					end   
                 end 
				 if c['type']!=nil and  c['type'] != ""
                   type.push(c['type'])
				 end  
			   end	 
            end	
			ac = a['accessConfigs'].to_s
      	    if addr_list.length > 0
    	       addr_list = "#{addr_list},#{n}:#{ip}\n#{type}:#{nat_ip}\n"
    	    else
    	       addr_list = "#{n}:#{ip}\n#{type}:#{nat_ip}\n"
            end			
            if  @google_server['Public_Addr'].text == "" 
               @google_server['Public_Addr'].text = ip
               @google_public_addr[instance_id] = ip
            end   
         end 
         @google_server['Addresses'].setText(addr_list) 		 
    	 @google_server['Tags'].text = r['tags'].to_s
    	 #if r.personality != nil
    	 #   @google_server['Personality'].text = r.personality
    	 #else
    	 #   @google_server['Personality'].text = ""
    	 #end
   	    @google_server['Flavor'].text = google_last(r['machineType'])
    	 if r['zone'] != nil
    	    @google_server['Availability_Zone'].text = google_last(r['zone'])
    	 else
    	    @google_server['Availability_Zone'].text =  ""
    	 end 
         @google_server['Scheduling'].text = r['scheduling'].to_s
		 disk_list = ""
   	     r['disks'].each do | a|
		   if disk_list == ""
              disk_list="#{google_last(a['source'])}:#{a['type']}:#{a['mode']}:#{a['deviceName']}"
		   else 
              disk_list="#{disk_list}\n#{google_last(a['source'])}:#{a['type']}:#{a['mode']}:#{a['deviceName']}"
           end 		   
		   if a['boot'] == true 
		      disk_list="#{disk_list}:boot"
		   end 	  
 		 end 
		 @google_server['Disks'].setText(disk_list) 
    	 if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
            @google_server['EC2_SSH_Private_Key'].text = get_pk
         else
            @google_server['Putty_Private_Key'].text = get_ppk
         end
         @google_server['EC2_SSH_User'].text = ""
         #instance_id = @google_server['Instance_ID'].text
         ssh_u = @ec2_main.launch.google_get('EC2_SSH_User')
         if ssh_u != nil and ssh_u != ""
            @google_server['EC2_SSH_User'].text = ssh_u
         end  
       	 if @google_admin_pw[instance_id] != nil and @google_admin_pw[instance_id] != ""
    	   @google_server['Admin_Password'].text = @google_admin_pw[instance_id]
    	 else
      	   if @ec2_main.launch.google_get('Name') == r[:name]
    	      @google_server['Admin_Password'].text = @ec2_main.launch.google_get('Admin_Password')
    	   else
    	       @google_server['Admin_Password'].text = ""
    	   end
    	 end
    	 if r[:password] != nil
	    @google_server['Admin_Password'].text =  r[:password]
	 end
     end
     @ec2_main.app.forceRefresh
  end 
 
 def google_terminate
   #instance = @google_server['Instance_ID'].text
   instance = @google_server['Name'].text
   answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Termination","Confirm Termination of Server Instance "+instance)
   if answer == MBOX_CLICKED_YES
       begin
          r = @ec2_main.environment.servers.delete_server(instance, @google_server['Availability_Zone'].text)
       rescue
          error_message("Terminate Instance Failed",$!)
       end      
   end 
 end 
 
  def google_get_chef_node
       instance_id = @google_server['Instance_ID'].text
       if @ec2_chef_node[instance_id] != nil and @ec2_chef_node[instance_id] != ""
   	cn =  @ec2_chef_node[instance_id]
       else  
         cn = @ec2_main.launch.get('Chef_Node')
         if cn == nil or cn == ""
          cn = @secgrp
         end
       end   
       return cn
  end 
  
  def google_last(parm)
    if parm == nil or parm == "" or parm.index('/') == nil
  	  return parm
	else  
 	  return parm.split("/").last
	end  
  end	
 
end