class EC2_Launch

 def launch_ops_instance
    puts "launch.launch_ops_instance"
    if @ops_launch['Name'].text != nil and @ops_launch['Name'].text != ""
        server = @ops_launch['Name'].text
    else
        error_message("Error","Name not specified")
        return
    end
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Launch","Confirm Launch of Server "+server)
    if answer == MBOX_CLICKED_YES
       launch_parm = Hash.new
       #if @ops_launch['Admin_Password'].text != nil and @ops_launch['Admin_Password'].text != ""
       #  launch_parm[:adminPass]= @ops_launch['Admin_Password'].text
       #end
       if @ops_launch['Minimum_Server_Count'].text != nil and @ops_launch['Minimum_Server_Count'].text != ""
         launch_parm['min_count']= (@ops_launch['Minimum_Server_Count'].text).to_i
       else
         launch_parm['min_count']= 1
       end
       if @ops_launch['Maximum_Server_Count'].text != nil and @ops_launch['Maximum_Server_Count'].text != ""
         launch_parm['max_count']= (@ops_launch['Maximum_Server_Count'].text).to_i
       else
         launch_parm['max_count']= 1
       end
       if @ops_launch['Keyname'].text != nil and @ops_launch['Keyname'].text != ""
          launch_parm['key_name']= @ops_launch['Keyname'].text
       # rackspace does not have keynames
       #else
       #   error_message("Launch Error","Keyname not specified")
       #   return
       end
       g = []
       if @ops_launch['Security_Group'].text != nil and @ops_launch['Security_Group'].text != ""
          a = @ops_launch['Security_Group'].text
          sa = (a).split(",")
          sa.each do |s|
            g.push(s)
          end
       end
       flavor_ref = @ops_launch['Flavor'].text
       launch_parm['security_groups'] = g
       if @ops_launch['Availability_Zone'].text != nil and @ops_launch['Availability_Zone'].text != ""
             launch_parm['availability_zone']= @ops_launch['Availability_Zone'].text
       end
       launch_parm[:metadata] = ""
       if @launch['User_Data'].text != nil and @launch['User_Data'].text != ""
             launch_parm['metadata']= @launch['User_Data'].text
       end
       ops_save
       server = @ops_launch['Security_Group'].text
       if @ops_launch['Name'].text != nil and @ops_launch['Name'].text != ""
         server = @ops_launch['Name'].text
       end
       image_ref = @ops_launch['Image_Id'].text

       if @ops_launch['AccessIPv4'].text != nil and @ops_launch['AccessIPv4'].text != ""
          launch_parm['accessIPv4'] =  @ops_launch['AccessIPv4'].text
       end
       if @ops_launch['AccessIPv6'].text != nil and @ops_launch['AccessIPv6'].text != ""
          launch_parm['accessIPv6'] =  @ops_launch['AccessIPv6'].text
       end
       puts "launch server "+server
       item_server = ""
       item = []
       begin
          puts "Create #{server}, #{image_ref}, #{flavor_ref}, #{launch_parm}"
          r =  @ec2_main.environment.servers.create_server(server, image_ref, flavor_ref, launch_parm)
          puts "*** returned from create server #{r}"
       rescue
          error_message("Launch of Server Failed",$!)
          return
       end
       instance_id = r['id'].to_s
       r[:aws_instance_id] = instance_id
       if r.instance_of?(Hash) and r['adminPass'] != nil
          @ops_launch['Admin_Password'].text = r['adminPass']
          ops_save
       end
       item_server = "#{r[:name]}/#{instance_id}"
       if launch_parm['min_count']>1 or launch_parm['max_count']>1
          @ec2_main.treeCache.refresh
       else
          @ec2_main.serverCache.addInstance(r)
       end
       @ec2_main.server.ops_clear_panel
       @ec2_main.server.load_server(item_server)
       @ec2_main.tabBook.setCurrent(1)
    end
 end



  def load_ops(parm)
       puts "Launch.load_ops"
       clear_ops_panel
       @type = "ops"
       @profile_type = "secgrp"
       @profile_folder = "opslaunch"
       @frame1.hide()
       @frame3.hide()
       @frame4.show()
       @frame5.hide()
	   @frame6.hide()
       @profile = parm
       @ops_launch['Name'].text = @profile
       @ops_launch['Name'].enabled = false
       @ops_launch['Chef_Node'].text = @profile
       @ops_launch['Image_Id'].enabled = true
       @ops_launch['Image_Id_Button'].enabled = true
       fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
       if File.exists?(fn)
        	File.open(fn, 'r') do |properties_file|
        	 properties_file.read.each_line do |line|
        	  line.strip!
        	  if (line[0] != ?# and line[0] != ?=)
        	    i = line.index('=')
        	    if (i)
        	      @properties[line[0..i - 1].strip] = line[i + 1..-1].strip
        	    else
        	      @properties[line] = ''
        	    end
        	  end
        	 end
         end

         load_ops_panel('Security_Group')
         load_ops_panel('Chef_Node')
         load_ops_panel('Image_Id')
         load_ops_panel('Image_Name')
         load_ops_panel('Flavor')
         load_ops_panel('Keyname')
         load_ops_panel('Admin_Password')
         load_ops_panel('EC2_SSH_User')
         load_ops_panel('SSH_Private_Key')
         load_ops_panel('Putty_Private_Key')
         load_ops_panel('Minimum_Server_Count')
         load_ops_panel('Maximum_Server_Count')
         load_ops_panel('Availability_Zone')
         load_ops_panel('User_Data')
         load_ops_panel('User_Data_File')
         load_ops_panel('AccessIPv4')
         load_ops_panel('AccessIPv6')
         @launch_loaded = true
       else
         # default to empty values
         @ops_launch['Name'].enabled = true
         ops_put('Keyname',"")
         @launch_loaded = true
       end
       load_notes
       @ec2_main.app.forceRefresh
 end

   def clear_ops_panel
     puts "Launch.clear_ops_panel"
     @type = "ops"
     @profile = ""
     @resource_tags = nil
     @frame1.hide()
     @frame3.hide()
     @frame4.show()
     @frame5.hide()
     ops_clear('Security_Group')
     ops_clear('Chef_Node')
     ops_clear('Admin_Password')
     @ops_launch['Name'].text = ""
     @ops_launch['Name'].enabled = true
     ops_clear('Image_Id')
     ops_clear('Image_Name')
     ops_clear('Flavor')
     ops_clear('Keyname')
     ops_clear('SSH_Private_Key')
     ops_clear('Minimum_Server_Count')
     ops_clear('Maximum_Server_Count')
     ops_clear('Availability_Zone')
     ops_clear('User_Data')
     ops_clear('User_Data_File')
     ops_clear('AccessIPv4')
     ops_clear('AccessIPv6')
     ops_clear('Image_Id')
     ops_clear('EC2_SSH_User')
     if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
        ops_clear('Putty_Private_Key')
     end
     clear_notes
     @launch_loaded = false
     #puts @launch['Security_Group'].text
   end

   def ops_clear(key)
      if key == 'Admin_Password'
         @properties.each_pair do |key, value|
            if key.start_with?('Admin_Password')
               @properties[key] = ""
            end
         end
      else
         @properties[key] = ""
      end
      @ops_launch[key].text = ""
   end

   def ops_put(key,value)
      puts "Launch.ops_put "+key
      if key == 'Admin_Password' and @properties['Name'] != nil and @properties['Name'] != ""
         @properties[key+"_"+@properties['Name']] = value
         @ops_launch[key].text = value
      else
         @properties[key] = value
         @ops_launch[key].text = value
      end
   end

   def ops_save
     puts "Launch.save_ops"
     @profile = @ops_launch['Name'].text
     @profile_folder = "opslaunch"
     if @profile == nil or @profile == ""
        error_message("Error","No Server Name specified")
     else
      load_ops_image  if !@ec2_main.settings.openstack_hp
      save_ops_launch('Security_Group')
      save_ops_launch('Chef_Node')
      save_ops_launch('Image_Id')
      save_ops_launch('Image_Name')
      save_ops_launch('Flavor')
      save_ops_launch('Keyname')
      save_ops_launch('Admin_Password')
      save_ops_launch('EC2_SSH_User')
      save_ops_launch('SSH_Private_Key')
      save_ops_launch('Putty_Private_Key')
      save_ops_launch('Minimum_Server_Count')
      save_ops_launch('Maximum_Server_Count')
      save_ops_launch('Availability_Zone')
      save_ops_launch('User_Data')
      save_ops_launch('User_Data_File')
      save_ops_launch('AccessIPv4')
      save_ops_launch('AccessIPv6')
      doc = ""
      @properties.each_pair do |key, value|
         if value != nil
            puts "#{key}=#{value}\n"
            doc = doc + "#{key}=#{value}\n"
         end
      end
      fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
      begin
         File.open(fn, "w") do |f|
            f.write(doc)
         end
         save_notes
         @launch_loaded = true
      rescue
         puts "launch loaded false"
         @launch_loaded = false
      end
     end
   end

   def load_ops_panel(key)
       if key == 'Admin_Password' and @properties['Name'] != nil and @properties['Name'] != ""
	  @ops_launch[key].text = @properties[key+"_"+@properties['Name']]
       elsif @properties[key] != nil
         @ops_launch[key].text = @properties[key]
       end
   end

   def save_ops_launch(key)
        puts "Launch.save_ops_launch"
        if key == 'Admin_Password' and @properties['Name'] != nil and @properties['Name'] != ""
	   @properties[key+"_"+@properties['Name']] = @ops_launch[key].text
        elsif @ops_launch[key].text != nil
          @properties[key] =  @ops_launch[key].text
        else
          @properties[key] = nil
        end
   end

   def ops_get(key)
      if key == 'Admin_Password' and @properties['Name'] != nil and @properties['Name'] != ""
	 return @properties[key+"_"+@properties['Name']]
      else
          return @properties[key]
      end
   end

   def ops_delete
      fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
      begin
         if File.exists?(fn)
            answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of launch profile "+@profile)
            if answer == MBOX_CLICKED_YES
               File.delete(fn)
               ft = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+"_tags.rb"
	       if File.exists?(ft)
                  File.delete(fn)
               end
              load_ops(@profile)
            end
         else
            error_message("Error","No Launch Profile for "+@profile+" to delete")
         end
      rescue
      end
   end




def load_ops_image
      puts "Launch.load_ops_image"
       image_id = @properties['Image_Id']
       if image_id != nil and image_id != ""
         begin
          r = @ec2_main.environment.images.get(image_id)
          if r != nil
            ops_put('Image_Name',r[:name])
          end
          #return r[:server]['links'][0]['href'] if !@ec2_main.settings.openstack_hp and !@ec2_main.settings.openstack_rackspace
         rescue
           puts "ERROR: Image not found"
           error_message("Error","Launch Profile: Image Id not found")
         end
       end
   end

end
