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
       ops_clear('Image_Name')
       ops_clear('State')
       ops_clear('Addr')
       ops_clear('Addr_Type')
       ops_clear('Progress')
       ops_clear('Personality')
       ops_clear('Flavor')
       ops_clear('Availability_Zone')
       ops_clear('Key_Name')
       #if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
       #   clear('EC2_SSH_Private_Key')
       #else
       #   clear('Putty_Private_Key')
       #end
       #clear('EC2_SSH_User')
       @frame1.hide()
       @frame2.hide()
       @page1.width=300
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
         @frame2.hide()
         @page1.width=300
         @frame3.show()
         @ops_server['Instance_ID'].text = instance_id
         ENV['EC2_INSTANCE'] = instance_id
     	 r = @ec2_main.serverCache.instance(instance_id)
     	 puts "ops instance #{r}"
    	 gp = @ec2_main.serverCache.instance_groups(instance_id)
    	 gp_list = ""
    	 gp.each do |g|
    	   if gp_list.length>0
    	    gp_list = gp_list+","+g
    	   else
    	    gp_list = g
    	    @secgrp = g
    	   end 
    	 end
    	 @ops_server['Security_Groups'].text = gp_list
    	 @ops_server['Name'].text = r.name
    	 @ops_server['Chef_Node'].text = ops_get_chef_node
    	 @ops_server['Image_ID'].text = r.image["id"]
    	 @ops_server['Image_Name'].text = image(r.image["id"])
    	 @ops_server['State'].text = r.state
    	 @server_status = @ops_server['State'].text
    	 @ops_server['Key_Name'].text = ""
    	 if r.addresses["internet"] != nil 
    	    @ops_server['Addr'].text = r.addresses["internet"][0]["addr"]
    	    @ops_server['Addr_Type'].text = "IPV#{r.addresses["internet"][0]["version"]}"
    	 else
    	     @ops_server['Addr'].text = ""
    	     @ops_server['Addr_Type'].text = ""
    	 end 
    	 @ops_server['Progress'].text = "#{r.progress}%"
    	 if r.personality != nil
    	    @ops_server['Personality'].text = r.personality
    	 else
    	    @ops_server['Personality'].text = ""
    	 end
    	 @ops_server['Flavor'].text = flavor(r.flavor["id"])
    	 if r.availability_zone != nil
    	    @ops_server['Availability_Zone'].text = r.availability_zone
    	 else
    	    @ops_server['Availability_Zone'].text =  ""
    	 end   
    	 #if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
         #   @server['EC2_SSH_Private_Key'].text = get_pk
         #else
         #   @server['Putty_Private_Key'].text = get_ppk
         #end
         #@server['EC2_SSH_User'].text = ""
         #instance_id = @server['Instance_ID'].text
         #ssh_u = @ec2_main.launch.get('EC2_SSH_User')
         #if ssh_u != nil and ssh_u != ""
         #   @server['EC2_SSH_User'].text = ssh_u
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
     	 @ec2_main.app.forceRefresh
  end 
 
 
  def ops_run_ssh
             s = @ops_server['Addr'].text
             if s == nil or s == ""
 	       s = currentServer
 	    end
 	    user = @ec2_main.launch.ops_get("SSH_User")
 	    adminPass = @ec2_main.launch.ops_get("Admin_Password")
 	    if user == nil or user == ""
 	       user = "root"
 	    end
             if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
 	       pk = ops_get_ppk
 	       if pk != nil and pk != ""
 	       	  c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/putty/putty.exe\" -ssh "+s+" -i "+"\""+pk+"\""+" -l "+user
 	          #c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/putty/putty.exe\" -ssh "+s+" -pw "+"\""+adminPass+"\""+" -l "+user
 	          puts c
 	          system(c)
 	       else
 	          error_message("Error","No Putty Private Key in Settings")
                end
             else
 	       pk = ops_get_pk
 	       if pk != nil and pk != ""
 	          te = "xterm"
                   if @ec2_main.settings.get_system('TERMINAL_EMULATOR') != nil and @ec2_main.settings.get_system('TERMINAL_EMULATOR') != ""
 	             te = @ec2_main.settings.get_system('TERMINAL_EMULATOR')
 	          end 
 	          if RUBY_PLATFORM.index("linux") != nil
 	             if te == "xterm"
                          c = "xterm -hold -e ssh -i "+pk+" "+s+" -l "+user+" &"
                      else 
                          c = te+ " -x ssh -i "+pk+" "+s+" -l "+user+" &"
                      end
 	          else
 		     if te == "xterm"
                          c = "xterm -e ssh -i "+pk+" "+s+" -l "+user+" &"
                      else 
                          c = te+ " -x ssh -i "+pk+" "+s+" -l "+user+" &"
                      end	          
 	          end	          
 	          puts c
 	          system(c)
 	       else
 	          error_message("Error","No SSH Private Key in Settings")
                end
             end
  end 
 
 
 def ops_terminate
   instance = @ops_server['Instance_ID'].text
   answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Termination","Confirm Termination of Server Instance "+instance)
   if answer == MBOX_CLICKED_YES
    conn = @ec2_main.environment.connection
    if conn != nil
       begin
          r = conn.servers.destroy(instance)
       rescue
          error_message("Terminate Instance Failed",$!.to_s)
       end      
    end
   end 
 end 
 
 def flavor(id)
   flavor_name = id.to_s
   if @flavor.length == 0
      conn = @ec2_main.environment.connection
      if conn != nil
         conn.flavors.each do |r|
            @flavor[r.id.to_s] = r
         end
      end
   end
   if @flavor[id] != nil 
      flavor_name =  @flavor[id].name
   end
   return flavor_name
 end  
     
  def image(id)
     image_name = id.to_s
     if @image.length == 0
        conn = @ec2_main.environment.connection
        if conn != nil
           conn.images.each do |r|
              @image[r.id.to_s] = r
           end
        end
     end
     if @image[id] != nil 
        image_name =  @image[id].name
     end
     return image_name
 end  
  
  
 
  def ops_get_chef_node
       instance_id = @ops_server['Instance_ID'].text
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
  
  def ops_get_pk
      instance_id = @ops_server['Instance_ID'].text
      if @ec2_ssh_private_key[instance_id] != nil and @ec2_ssh_private_key[instance_id] != ""
  	pk =  @ec2_ssh_private_key[instance_id]
      else  
        pk = @ec2_main.launch.ops_get('SSH_Private_Key')
        if pk == nil or pk == ""
         pk = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY')
        end
      end   
      return pk
    end   
    
    def ops_get_ppk
      instance_id = @ops_server['Instance_ID'].text
      if @putty_private_key[instance_id] != nil and @putty_private_key[instance_id] != ""
  	pk =  @putty_private_key[instance_id]
      else	  
         pk = @ec2_main.launch.ops_get('Putty_Private_Key')
         if pk == nil or pk == ""
            pk = @ec2_main.settings.get('PUTTY_PRIVATE_KEY')
         end
      end   
      return pk
  end  

end