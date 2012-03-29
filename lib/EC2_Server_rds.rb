class EC2_Server

#
# rds methods
#

  def rds_loaded
         if @type == "rds" and @server_status == "available"
          return true
         else
          return false 
         end 
  end

  def run_mysql_admin
      addr = @rds_server['Address'].text
      port = @rds_server['Port'].text
      user = @rds_server['MasterUsername'].text
      pwd = ""
      if @rds_server['MasterUserPassword'].text != nil and @rds_server['MasterUserPassword'].text != ""
         pwd = @rds_server['MasterUserPassword'].text
      else   
         error_message("Error","No MySQL Master User Password specified")
         return
      end
      admin_cmd = "C:/Program Files/MySQL/MySQL Tools for 5.0/MySQLAdministrator.exe"
      if ENV['EC2DREAM_MYSQL_ADMIN'] != nil and ENV['EC2DREAM_MYSQL_ADMIN'] != ""
         admin_cmd = ENV['EC2DREAM_MYSQL_ADMIN']
      end
      if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
          c = "cmd.exe /c \@start \"\" /b \""+admin_cmd+"\" -h "+addr+" -P "+port+" -u "+user+" -p "+pwd
  	  puts c
  	  system(c)
      end
  end

  def load_rds_server(server)
        sa = (server).split"/"
        if sa.size>1
          load_rds(sa[sa.size-1])
        end        
  end

 def clear_rds_panel
     @type = ""
     ENV['EC2_INSTANCE'] = ""
     rds_clear('DBSecurity_Groups')
     rds_clear('DBInstanceId')
     rds_clear('DBName')
     rds_clear('DBInstanceClass')
     rds_clear('AllocatedStorage')
     rds_clear('AvailabilityZone')
     rds_clear('MultiAZ')
     rds_clear('Engine')
     rds_clear('EngineVersion')
     rds_clear('MasterUsername')
     rds_clear('MasterUserPassword')
     rds_clear('DBInstance_Status')
     rds_clear('Instance_Create_Time')
     rds_clear('Latest_Restorable_Time')
     rds_clear('PreferredMaintenanceWindow')
     rds_clear('DBParameterGroupName')
     rds_clear('BackupRetentionPeriod')
     rds_clear('PreferredBackupWindow')
     rds_clear('Port')
     rds_clear('Address')
     rds_clear('AutoMinorVersionUpgrade')
     rds_clear('ReadReplicaSourceDBInstanceId')
     rds_clear('ReadReplicaDBInstanceIds') 
     @frame1.hide()
     @page1.width=300
     @frame2.show()
     @frame3.hide()
     @server_status = ""
     @secgrp = ""
     @ec2_main.app.forceRefresh()
  end

  def rds_clear(key)
    @rds_server[key].text = ""
  end    

def load_rds(instance_id)
      puts "load_rds #{instance_id}"
      @type = "rds"
      @frame1.hide()
      @frame2.show()
      @frame3.hide()
      clear_rds_panel
      @rds_server['DBInstanceId'].text=instance_id
      r = @ec2_main.serverCache.DBInstance(instance_id)
      if r == nil
         @server_status = "Deleted"
	 @rds_server['DBInstance_Status'].text="Deleted"
	 @rds_server['Port'].text=""
	 @rds_server['Address'].text=""
      else
         @rds_server['DBSecurity_Groups'].text=""
         @rds_server['DBName'].text=""
         @rds_server['DBInstanceClass'].text=""
         @rds_server['AllocatedStorage'].text=""
         @rds_server['AvailabilityZone'].text=""
         @rds_server['MultiAZ'].text=""
         @rds_server['Engine'].text=""
         @rds_server['EngineVersion'].text=""
         @rds_server['MasterUsername'].text=""
         @rds_server['MasterUserPassword'].text=""
         @rds_server['DBInstance_Status'].text=""  
         @rds_server['Instance_Create_Time'].text=""	   
         @rds_server['Latest_Restorable_Time'].text=""    
         @rds_server['PreferredMaintenanceWindow'].text=""
         @rds_server['DBParameterGroupName'].text = ""
         @rds_server['BackupRetentionPeriod'].text=""
         @rds_server['PreferredBackupWindow'].text=""
         @rds_server['Port'].text=""	
         @rds_server['Address'].text=""
         @rds_server['AutoMinorVersionUpgrade'].text="" 
         @rds_server['ReadReplicaSourceDBInstanceId'].text="" 
         @rds_server['ReadReplicaDBInstanceIds'].text="" 
         @server_status = ""
         
         if r[:db_security_groups] != nil
	    if r[:db_security_groups].class == Array
      	       gp = r[:db_security_groups]
      	       gp_list = ""
      	       if gp != nil
      	          gp.each do |g|
      	             if gp_list.length>0
      	                gp_list = "#{gp_list},#{g[:name]} (#{g[:status]})"
      	             else
 			gp_list = "#{g[:name]} (#{g[:status]})"
      	                @secgrp = g[:name]
      	             end   
      	          end 
      	       end
      	       @rds_server['DBSecurity_Groups'].text=gp_list
      	    end     	       
      	 end   
	 if r[:name] != nil
	    @rds_server['DBName'].text=r[:name]
	 end   
	 if r[:instance_class] != nil   
	    @rds_server['DBInstanceClass'].text=r[:instance_class]
 	 end 
	 if r[:allocated_storage] != nil
	    @rds_server['AllocatedStorage'].text=r[:allocated_storage].to_s
	 end   
	 if r[:availability_zone] != nil
	    @rds_server['AvailabilityZone'].text=r[:availability_zone]
	 end 
	 if r[:multi_az] != nil
	    @rds_server['MultiAZ'].text=r[:multi_az].to_s
	 end     
	 if r[:engine] != nil
	    @rds_server['Engine'].text=r[:engine]
	 end 
	 if r[:engine_version] != nil
	    @rds_server['EngineVersion'].text=r[:engine_version]
	 end     
	 if r[:master_username] != nil
	    @rds_server['MasterUsername'].text=r[:master_username]
	 end
	 if @mysql_admin_pw[instance_id] != nil 
	    @rds_server['MasterUserPassword'].text=@mysql_admin_pw[instance_id]
	 end
	 if r[:status] != nil
	    puts "Status #{r[:status]}"
	    @server_status = r[:status]
	    @rds_server['DBInstance_Status'].text=r[:status]
	 end 
     	 t = r[:create_time]
     	 if t != nil
      	    tzone = @ec2_main.settings.get_system('TIMEZONE')
     	    if tzone != "UTC"
     	       tz = TZInfo::Timezone.get(tzone)
   	       t = tz.utc_to_local(DateTime.new(t[0,4].to_i,t[5,2].to_i,t[8,2].to_i,t[11,2].to_i,t[14,2].to_i,t[17,2].to_i)).to_s
            end
  	    i = t.index("T")
     	    if i != nil and i> 0
     	        t[i] = " "
     	    end
     	    i = t.index("Z")
   	    if i != nil and i> 0
   	        t[i] = " "
     	    end
	    @rds_server['Instance_Create_Time'].text=t
	 end
         @rds_server['Latest_Restorable_Time'].text = ""
	 t = r[:latest_restorable_time]
     	 if t != nil
      	    tzone = @ec2_main.settings.get_system('TIMEZONE')
     	    if tzone != "UTC"
     	       tz = TZInfo::Timezone.get(tzone)
   	       t = tz.utc_to_local(DateTime.new(t[0,4].to_i,t[5,2].to_i,t[8,2].to_i,t[11,2].to_i,t[14,2].to_i,t[17,2].to_i)).to_s
            end
  	    i = t.index("T")
     	    if i != nil and i> 0
     	        t[i] = " "
     	    end
     	    i = t.index("Z")
   	    if i != nil and i> 0
   	        t[i] = " "
     	    end
	    @rds_server['Latest_Restorable_Time'].text=t
	 end	 
         @rds_server['PreferredMaintenanceWindow'].text = ""
	 if r[:preferred_maintenance_window] != nil
	    @rds_server['PreferredMaintenanceWindow'].text=r[:preferred_maintenance_window]
	 end
	 if r[:db_parameter_group] != nil
	    gp = r[:db_parameter_group]
	    @rds_server['DBParameterGroupName'].text = gp[:name]+" ("+gp[:status]+")"
     	 end	 
	 if r[:backup_retention_period] != nil
	    @rds_server['BackupRetentionPeriod'].text=r[:backup_retention_period].to_s
	 end   
	 if r[:preferred_backup_window] != nil
	    @rds_server['PreferredBackupWindow'].text=r[:preferred_backup_window]
	 end   
	 if r[:endpoint_port] != nil
	    @rds_server['Port'].text=r[:endpoint_port].to_s
	 end   
	 if r[:endpoint_address] != nil
	    @rds_server['Address'].text=r[:endpoint_address]
	 end 
	 if r[:auto_minor_version_upgrade] != nil
	    @rds_server['AutoMinorVersionUpgrade'].text=r[:auto_minor_version_upgrade].to_s
	 end 
	 if r[:read_replica_source_db_instance_id] != nil
	    @rds_server['ReadReplicaSourceDBInstanceId'].text=r[:read_replica_source_db_instance_id]
	 end 
	 if r[:read_replica_db_instance_ids] != nil
	    if r[:read_replica_db_instance_ids].class == Array
     	       rr_list = ""
     	       r[:read_replica_db_instance_ids].each do |rr|
     	          if rr_list.length>0
                     rr_list = "#{rr_list},#{rr}"
     	          else
     	             rr_list = "#{rr}"
     	          end 
     	       end
	       @rds_server['ReadReplicaDBInstanceIds'].text=rr_list
	    end
	 end   
      end
      @page1.width=300
      @ec2_main.app.forceRefresh
 end

 def reboot_rds(instance)
      answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Reboot","Confirm Reboot of DB Instance "+instance)
      if answer == MBOX_CLICKED_YES
         rds = @ec2_main.environment.rds_connection
         if rds != nil
            begin
               r = rds.reboot_db_instance(instance)
               @rebooted = true
            rescue
               error_message("Reboot DB Instance Failed",$!.to_s)
            end      
         end
      end 
 end 
 
 end