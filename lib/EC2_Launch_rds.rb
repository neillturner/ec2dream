class EC2_Launch


 def launch_rds_Panel(item)
       load_rds(item.text)
 end 
 
 def launch_rds_instance
    puts "launch.launch_rds_instance"
    server = @rds_launch['DBInstanceId'].text
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Launch","Confirm Launch of DB Instance "+server)
    if answer == MBOX_CLICKED_YES
     rds = @ec2_main.environment.rds_connection
     if rds != nil
       launch_parm = Hash.new
       dbname = @rds_launch['DBName'].text
       g = Array.new
       if @rds_launch['Additional_DBSecurity_Groups'].text == nil or @rds_launch['Additional_DBSecurity_Groups'].text == ""
          g[0] = @rds_launch['DBSecurity_Group'].text
       else
          g[0] = @rds_launch['DBSecurity_Group'].text
          a = @rds_launch['Additional_DBSecurity_Groups'].text
          i = 1
          a.each(",") do |s|
           g[i] = s[0..s.length-1]
           i = i+1
          end 
       end
       launch_parm[:db_security_groups] = g       
       launch_parm[:aws_id] = @rds_launch['DBInstanceId'].text
       launch_parm[:db_name] = @rds_launch['DBName'].text
       launch_parm[:instance_class] = @rds_launch['DBInstanceClass'].text
       if @rds_launch['AllocatedStorage'].text != nil and @rds_launch['AllocatedStorage'].text != ""
          launch_parm[:allocated_storage] = (@rds_launch['AllocatedStorage'].text).to_i
       end   
       launch_parm[:availability_zone] = @rds_launch['AvailabilityZone'].text
       if @rds_launch['MultiAZ'].itemCurrent?(0)
          launch_parm[:multi_az] = "true"
        end
       launch_parm[:engine] = @rds_launch['Engine'].text
       launch_parm[:engine_version] = @rds_launch['EngineVersion'].text
       launch_parm[:master_username] = @rds_launch['MasterUsername'].text
       launch_parm[:master_user_password] = @rds_launch['MasterUserPassword'].text
       launch_parm[:preferred_maintenance_window] = @rds_launch['PreferredMaintenanceWindow'].text
       launch_parm[:db_parameter_group] = @rds_launch['DBParameterGroupName'].text
       launch_parm[:backup_retention_period] = @rds_launch['BackupRetentionPeriod'].text
       launch_parm[:preferred_backup_window] = @rds_launch['PreferredBackupWindow'].text
       launch_parm[:endpoint_port] = @rds_launch['Port'].text
       if @rds_launch['AutoMinorVersionUpgrade'].itemCurrent?(1)
          launch_parm[:auto_minor_version_upgrade] = "false"
        end
 
       rds_save
       puts "launch server "+server
       begin
         item = ""
         r = rds.create_db_instance(launch_parm[:aws_id], launch_parm[:master_username], launch_parm[:master_user_password], launch_parm)
         item = "DBInstance/"+r[:aws_id]
         @ec2_main.serverCache.addDBInstance(r)
         if item != ""
            @ec2_main.server.load_rds_server(item)
            @ec2_main.tabBook.setCurrent(1)
         end
       rescue
         error_message("Launch Failed",$!.to_s)
       end  
     end
    end 
 end     
 
  def launch_rds_read_replica(rr)
    puts "launch.launch_rds_read_replica"
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Launch","Confirm Launch of Read Replica DB Instance #{rr[:db_instance_id]}")
    if answer == MBOX_CLICKED_YES
       rds = @ec2_main.environment.rds_connection
       if rds != nil
          begin
             item = ""
             r = rds.create_db_instance_read_replica(rr[:db_instance_id], rr[:source_db_instance_id], rr)
             item = "DBInstance/"+r[:aws_id]
             @ec2_main.serverCache.addDBInstance(r)
             if item != ""
                @ec2_main.server.load_rds_server(item)
                @ec2_main.tabBook.setCurrent(1)
             end
          rescue
             error_message("Launch Failed",$!.to_s)
          end
       end
    end  
  end

 def restore_rds_instance
     puts "launch.restore_rds_instance"
     server = @rds_launch['DBInstanceId'].text
     snap = @rds_launch['DBSnapshot'].text
     params = {}
     params[:instance_class] = @rds_launch['DBInstanceClass'].text
     params[:endpoint_port] = @rds_launch['Port'].text
     params[:availability_zone] = @rds_launch['AvailabilityZone'].text
     if @rds_launch['MultiAZ'].itemCurrent?(0)
        params[:multi_az] = "true"
     end
     if @rds_launch['AutoMinorVersionUpgrade'].itemCurrent?(1)
        params[:auto_minor_version_upgrade] = "false"
     end        
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Restore","Confirm Restore of DB Instance "+server+" from DBsnapshot "+snap)
     if answer == MBOX_CLICKED_YES
        rds = @ec2_main.environment.rds_connection
        if rds != nil
           begin 
              r = rds.restore_db_instance_from_db_snapshot(snap, server, params)
              @created = true
              item = "DBInstance/"+r[:aws_id]
              @ec2_main.serverCache.addDBInstance(r)
              if item != ""
                 @ec2_main.server.load_rds_server(item)
                 @ec2_main.tabBook.setCurrent(1)
              end
           rescue
              error_message("Restore DBInstance Failed",$!.to_s)
           end  
        end
     end 
 end     
 
 def load_rds(sec_grp)
      puts "Launch.load"
      @type = "rds"
      @frame1.hide()
      @frame2.show()
      @frame3.hide()
      @frame4.hide()
      @profile_type = "secgrp"
      @profile_folder = "dblaunch"
      clear_rds_panel
      @profile = sec_grp
      @rds_launch['DBSecurity_Group'].text = @profile
      @rds_launch['DBSecurity_Group'].enabled = false
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
        load_rds_panel('DBSecurity_Group')
        load_rds_panel('Additional_DBSecurity_Groups')
        load_rds_panel('DBInstanceId')
        load_rds_panel('DBName')
        load_rds_panel('DBInstanceClass')
        load_rds_panel('AllocatedStorage')
        load_rds_panel('AvailabilityZone')
	load_rds_panel_true_false('MultiAZ')
        load_rds_panel('Engine')
        load_rds_panel('EngineVersion')
        #load_ApplyImmediately
        load_rds_panel('MasterUsername')
        load_rds_panel('MasterUserPassword')
        load_rds_panel('PreferredMaintenanceWindow')
        load_rds_panel('DBParameterGroupName')
        load_rds_panel('BackupRetentionPeriod')
        load_rds_panel('PreferredBackupWindow')
        load_rds_panel('DBSnapshot')
        load_rds_panel('Port')
        load_rds_panel_true_false('AutoMinorVersionUpgrade')
        load_rds_read_replica
        @launch_loaded = true
      else
        # default to empty values
        @rds_launch['DBInstanceId'].text = sec_grp
        @rds_launch['DBInstanceClass'].text = "db.m1.small"
        @rds_launch['AllocatedStorage'].text = "5"
        @rds_launch['Engine'].text = "mysql"
        @rds_launch['EngineVersion'].text = "5.1.45"
        @rds_launch['PreferredMaintenanceWindow'].text = "Sun:05:00-Sun:09:00"
        @rds_launch['BackupRetentionPeriod'].text = "0"
        @rds_launch['PreferredBackupWindow'].text = "01:00-03:00"
        @rds_launch['Port'].text = "3306"
        @rds_launch['MultiAZ'].setCurrentItem(1)
        @rds_launch['AutoMinorVersionUpgrade'].setCurrentItem(0)
        @launch_loaded = true
      end
      load_notes      
      @ec2_main.app.forceRefresh
 end 
   
    
   def load_rds_panel_true_false(field)
     if @properties[field] == 'true'
        @rds_launch[field].setCurrentItem(0)
     else
        @rds_launch[field].setCurrentItem(1)
     end   
   end
   
   def load_rds_panel(key)
    if @properties[key] != nil
      @rds_launch[key].text = @properties[key]
    end
   end 
   
   def clear_rds_panel
     puts "Launch.clear_rds_panel" 
     @profile = ""
     @resource_tags = nil 
     rds_clear('DBSecurity_Group')
     rds_clear('Additional_DBSecurity_Groups')
     rds_clear('DBInstanceId')
     rds_clear('DBName')
     rds_clear('DBInstanceClass')
     rds_clear('AllocatedStorage')
     rds_clear('AvailabilityZone')
     rds_clear_false('MultiAZ')
     rds_clear('Engine')
     rds_clear('EngineVersion')
     rds_clear('MasterUsername')
     rds_clear('MasterUserPassword')
     rds_clear('PreferredMaintenanceWindow')
     rds_clear('DBParameterGroupName')
     rds_clear('BackupRetentionPeriod')
     rds_clear('PreferredBackupWindow')
     rds_clear('DBSnapshot')
     rds_clear('Port')
     rds_clear_true('AutoMinorVersionUpgrade')
     rds_clear_read_replica
     clear_notes     
     @launch_loaded = false
     #puts @rds_launch['Security_Group'].text
   end 
   
   def rds_clear_true(field)
      @properties[field] = ""
      @rds_launch[field].setCurrentItem(0)
   end 
   def rds_clear_false(field)
      @properties[field] = ""
      @rds_launch[field].setCurrentItem(1)
   end 
   
   def rds_clear(key)
      @properties[key] = ""
      @rds_launch[key].text = ""
   end  
   
   #def get(key)
   #   return @properties[key]
   #end
   
   def rds_put(key,value)
      puts "Launch.put "+key
      @properties[key] = value
      @rds_launch[key].text = value
   end 
   
   def rds_save
      puts "Launch.save"
      save_rds_launch('DBSecurity_Group')
      save_rds_launch('Additional_DBSecurity_Groups')
      save_rds_launch('DBInstanceId')
      save_rds_launch('DBName')
      save_rds_launch('DBInstanceClass')
      save_rds_launch('AllocatedStorage')
      save_rds_launch('AvailabilityZone')
      save_rds_launch_true_false('MultiAZ')
      save_rds_launch('Engine')
      save_rds_launch('EngineVersion')
      #save_ApplyImmediately
      save_rds_launch('MasterUsername')
      save_rds_launch('MasterUserPassword')
      save_rds_launch('PreferredMaintenanceWindow')
      save_rds_launch('DBParameterGroupName')
      save_rds_launch('BackupRetentionPeriod')
      save_rds_launch('PreferredBackupWindow')
      save_rds_launch('DBSnapshot')
      save_rds_launch('Port')
      save_rds_launch_true_false('AutoMinorVersionUpgrade')
      save_rds_read_replica
      doc = ""
      @properties.each_pair do |key, value|
       doc = doc + "#{key}=#{value}\n"
      end
      fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
      if !File.directory?(@ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder)
      	  FileUtils.mkdir_p @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder
      end      
      File.open(fn, "w") do |f|
        f.write(doc)
      end
      save_notes
      @launch_loaded = true
   end
   
   def rds_delete
      fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
      if File.exists?(fn)
         answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of DB launch profile "+@profile)
         if answer == MBOX_CLICKED_YES
           File.delete(fn)
           load_rds(@profile)
         end
      else
         error_message("Error","No DB Launch Profile for "+@profile+" to delete") 
      end    
   end 
   
   def save_rds_launch_true_false(field)
        if @rds_launch[field].itemCurrent?(0) 
	    @properties[field]="true"  
	else
	    @properties[field]="false" 
        end
   end
   
   def save_rds_launch(key)
     puts "Launch.save_setting"  
     if @rds_launch[key].text != nil
       @properties[key] =  @rds_launch[key].text
     else
       @properties[key] = nil
     end
   end

   def rds_clear_read_replica
      @read_replica = Array.new 
      @rds_launch['Read_Replicas'].clearItems
      @rds_launch['Read_Replicas'].rowHeaderWidth = 0	
      @rds_launch['Read_Replicas'].setTableSize(@read_replica.size, 1)
      @rds_launch['Read_Replicas'].setColumnText(0, "Read Replica Instance Id") 
      @rds_launch['Read_Replicas'].setColumnWidth(0,200)
   end

   def load_rds_read_replica
      @read_replica = Array.new 
      for i in 1..5 
         if @properties["ReadReplica_#{i}_db_instance_id"] != nil and @properties["ReadReplica_#{i}_db_instance_id"] != ""  
            rr = {} 
            rr[:db_instance_id] 	= @properties["ReadReplica_#{i}_db_instance_id"]
            rr[:source_db_instance_id] 	= @properties["ReadReplica_#{i}_source_db_instance_id"] 
            rr[:instance_class] 	= @properties["ReadReplica_#{i}_instance_class"]
            rr[:endpoint_port] 		= @properties["ReadReplica_#{i}_endpoint_port"]
            rr[:availability_zone] 	= @properties["ReadReplica_#{i}_availability_zone"]
 	    rr[:auto_minor_version_upgrade] = @properties["ReadReplica_#{i}_auto_minor_version_upgrade"] 
            @read_replica.push(rr)
         end   
      end
      load_rds_read_replica_table
   end
   
   def save_rds_read_replica
      i=0
      @read_replica.each do |rr|
         if rr!= nil
            i=i+1
            @properties["ReadReplica_#{i}_db_instance_id"] 		=  rr[:db_instance_id].to_s 
            @properties["ReadReplica_#{i}_source_db_instance_id"] 	=  rr[:source_db_instance_id]
            @properties["ReadReplica_#{i}_instance_class"] 		=  rr[:instance_class].to_s
            @properties["ReadReplica_#{i}_endpoint_port"] 		=  rr[:endpoint_port].to_s
            @properties["ReadReplica_#{i}_availability_zone"] 	=  rr[:availability_zone].to_s
 	    @properties["ReadReplica_#{i}_auto_minor_version_upgrade"] =  rr[:auto_minor_version_upgrade].to_s
          end
       end
   end

   def load_rds_read_replica_table
         @rds_launch['Read_Replicas'].clearItems
         @rds_launch['Read_Replicas'].rowHeaderWidth = 0	
         @rds_launch['Read_Replicas'].setTableSize(@read_replica.size, 1)
         @rds_launch['Read_Replicas'].setColumnText(0, "Read Replica Instance Id") 
         @rds_launch['Read_Replicas'].setColumnWidth(0,200)
         i = 0
         @read_replica.each do |m|
           if m!= nil 
              @rds_launch['Read_Replicas'].setItemText(i, 0, "#{m[:db_instance_id]}")
              @rds_launch['Read_Replicas'].setItemJustify(i, 0, FXTableItem::LEFT)
              i = i+1
   	     end 
         end
         @read_replica_curr_row = nil    
   end

end
