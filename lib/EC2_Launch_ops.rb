
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
     conn = @ec2_main.environment.connection
     if conn != nil
       launch_parm = Hash.new
       #if @ops_launch['Admin_Password'].text != nil and @ops_launch['Admin_Password'].text != ""
       #  launch_parm[:adminPass]= @ops_launch['Admin_Password'].text
       #end
       #if @launch['Keypair'].text != nil and @launch['Keypair'].text != ""
       #   launch_parm[:key_name]= @launch['Keypair'].text
       #else 
       #   error_message("Launch Error","Keypair not specified")
       #   return
       #end
       #it = (@launch['Instance_Type'].text).downcase
       #launch_parm[:group_names] = g 
       #if @launch['Availability_Zone'].text != nil and @launch['Availability_Zone'].text != ""
       #      launch_parm[:availability_zone]= @launch['Availability_Zone'].text
       #end
       #launch_parm[:user_data] = ""
       #if @launch['User_Data'].text != nil and @launch['User_Data'].text != ""
       #      launch_parm[:user_data]= @launch['User_Data'].text
       #end
       #if @launch['User_Data_File'].text != nil and @launch['User_Data_File'].text != ""
       #    fn = @launch['User_Data_File'].text
       #    d = ""
       #    begin 
       #       f = File.open(fn, "r")
       #      d = f.read
       #       f.close
       #    rescue 
       #       puts "***Error could not read user data file"
       #       error_message("Launch Error","Could not read User Data File")
       #       return
       #    end
       #    if launch_parm[:user_data] != nil and launch_parm[:user_data] != ""
       #       launch_parm[:user_data]=launch_parm[:user_data]+","+d
       #    else
       #       launch_parm[:user_data]=d
       #    end   
       #end
       ops_save
       launch_parm[:name] = @ops_launch['Name'].text
       launch_parm[:image_ref] = @ops_launch['Image_Id'].text
       flavor_ref = ""
       conn.flavors.each do |r|
          if r.name == @ops_launch['Flavor'].text
             flavor_ref= r.id
          end   
       end
       launch_parm[:flavor_ref] = flavor_ref
       puts "launch server "+server
       item_server = ""
       item = []
       begin
          server = conn.servers.create(launch_parm)
          if @ops_launch['Admin_Password'].text != nil and @ops_launch['Admin_Password'].text != ""
             server.adminPass = @ops_launch['Admin_Password'].text
          end   
       rescue 
          error_message("Launch of Server Failed",$!.to_s)
          return
       end
       puts "item #{item}"
       #instances = []
       #item.each do |r|
       #   if item_server == ""
       #      gi = r[:groups][0][:group_name]
       #      item_server = gi+"/"+r[:aws_instance_id]
       #   end
       #   instances.push(r[:aws_instance_id]) 
       #   @ec2_main.serverCache.addInstance(r)
       #end
       #if item_server != ""
       #   @ec2_main.server.load_server(item_server)
       #   @ec2_main.tabBook.setCurrent(1)
       #end   
    end
   end 
 end 
 
 
 
  def load_ops(sec_grp)
       puts "Launch.load_ops"
       clear_panel      
       @type = "ops"
       @profile_type = "secgrp"
       @profile_folder = "opslaunch"
       @frame1.hide()
       @frame2.hide()
       @frame3.hide()
       @frame4.show()
       @profile = sec_grp
       @ops_launch['Security_Group'].text = @profile
       @ops_launch['Security_Group'].enabled = false
       @ops_launch['Chef_Node'].text = @profile
       @ops_launch['Name'].text = @profile
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
         load_ops_panel('Name')         
         load_ops_panel('Image_Id')
         load_ops_panel('Image_Name')
         load_ops_panel('Flavor')
         load_ops_panel('Keyname')
         load_ops_panel('Admin_Password')
         load_ops_panel('SSH_Private_Key')
         load_ops_panel('Putty_Private_Key')
         load_ops_panel('User_Data_File')
         @launch_loaded = true
       else
         # default to empty values
         keypair = @ec2_main.settings.get('KEYPAIR_NAME')
         if keypair != nil and keypair != ""
          ops_put('Keyname',keypair)
         else 
          ops_put('Keyname',"trystack")
          end
         @launch_loaded = true
       end
       load_notes
       @ec2_main.app.forceRefresh
 end 

   def ops_put(key,value)
      puts "Launch.ops_put "+key
      @properties[key] = value
      @ops_launch[key].text = value
   end 

   def ops_save
      puts "Launch.save_ops"
      load_ops_image
      save_ops_launch('Security_Group')
      save_ops_launch('Chef_Node')
      save_ops_launch('Name')
      save_ops_launch('Image_Id')
      save_ops_launch('Image_Name')
      save_ops_launch('Flavor')
      save_ops_launch('Keyname')
      save_ops_launch('Admin_Password')
      save_ops_launch('SSH_Private_Key')
      save_ops_launch('Putty_Private_Key')
      save_ops_launch('User_Data')
      save_ops_launch('User_Data_File')
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
   
   def load_ops_panel(key)
       if @properties[key] != nil
         @ops_launch[key].text = @properties[key]
       end
   end 
   
   def save_ops_launch(key)
        puts "Launch.save_ops_launch"  
        if @ops_launch[key].text != nil
          @properties[key] =  @ops_launch[key].text
        else
          @properties[key] = nil
        end
   end

   def ops_get(key)
      return @properties[key]
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
      conn = @ec2_main.environment.connection
      if conn != nil
       image_id = @properties['Image_Id']
       if image_id != nil and image_id != ""
         begin 
          r = conn.images.get(image_id)
          if r != nil 
            ops_put('Image_Name',r.name) 
          end            
         rescue
          puts "**Error Image not found"
          error_message("Error","Launch Profile: Image Id not found")
         end
       end   
      end
   end

end
