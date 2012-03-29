
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'common/OPS_secgrp'


class EC2_ServerCache 

def initialize(owner, tree)
        @ec2_main = owner
        @tree = tree
        @ops_secgrp = OPS_SecGrp.new(owner)
	@instances = {}
        @sg_instances = {}
        @serverList= Array.new
        @sg_active_instances = {}
        @securityGrps = Array.new
        @secGrps = {}
        @db_instances = {}
        @db_sg_instances = {}
        @db_Security_Grps = Array.new
        @db_secGrps = {}
	@light 	   = @ec2_main.makeIcon("server.png")
	@light.create
	@nolight 	   = @ec2_main.makeIcon("stop.png")
	@nolight.create
	@parallel 	   = @ec2_main.makeIcon("rocket.png")
        @parallel.create
	@paralleldb 	   = @ec2_main.makeIcon("rocketdb.png")
        @paralleldb.create
	@connect    = @ec2_main.makeIcon("connect.png")
	@connect.create
	@disconnect = @ec2_main.makeIcon("disconnect.png")
	@disconnect.create 
	@database = @ec2_main.makeIcon("database.png")
	@database.create
	@camera = @ec2_main.makeIcon("camera.png")
	@camera.create
	@cross = @ec2_main.makeIcon("cross.png")
	@cross.create
        @reboot = @ec2_main.makeIcon("arrow_red_redo.png")
	@reboot.create
	@link_break = @ec2_main.makeIcon("link_break.png")
	@link_break.create
	@stopped = @ec2_main.makeIcon("cancel.png")
	@stopped.create 
end  


 def refreshServerTree(tree, serverBranch, doc, light, nolight, connect, disconnect)
    settings = @ec2_main.settings
    if settings.get("EC2_PLATFORM") == "openstack"
       ops_refreshServerTree(tree, serverBranch, doc, light, nolight, connect, disconnect) 
    else
       puts "ServerCache.refreshServerTree"
       keypair = ""
       if settings.get('KEYPAIR_NAME') != nil and settings.get('KEYPAIR_NAME').length>0
          keypair = settings.get('KEYPAIR_NAME')
       end
       ec2 = @ec2_main.environment.connection
       puts "return from ec2 connection"
       if ec2 != nil
          @securityGrps = Array.new
          eip = {}
          i=0
          begin
             ec2.describe_security_groups.each do |r|
                @secGrps[r[:aws_group_name]]=r
                @securityGrps[i] = r[:aws_group_name]
                i = i+1
             end
             ec2.describe_addresses.each do |r|
                if r[:instance_id] != nil and r[:instance_id] != ""
  	          eip[r[:instance_id]] = r[:public_ip]
                end  
             end
          rescue 
	    puts "***Error on connection to EC2 - check your keys in ServerCache.refreshServerTree"
            error_message("EC2 Connection Error",$!.to_s+" - check your EC2 Access Settings")
            @ec2_main.environment.set_connection_failed
            return
          end              
          @securityGrps = @securityGrps.sort
          @instances = {}
          @sg_instances = {}
          @sg_active_instances = {}
          @tags_filter= @ec2_main.settings.load_filter()
          ec2.describe_instances([],@tags_filter[:instance]).each do |r|
             instance_id = r[:aws_instance_id]
             if eip[instance_id] != nil
               r[:public_ip] = eip[instance_id]
             end  
             @instances[instance_id]=r
             if r[:groups][0][:group_name] == nil
	        gn = r[:groups][0][:group_id]
	     else
	        gn = r[:groups][0][:group_name]
             end 
             if @sg_instances[gn] == nil
                ig = Array.new
                ig[0]= instance_id
             else
                ig = @sg_instances[gn]
                i = ig.size
                ig[i] = instance_id
             end
             @sg_instances[gn] = ig
             if r[:aws_state] == "running"
                if @sg_active_instances[gn] == nil
	           ig = Array.new
	           ig[0]= instance_id
	        else
	           ig = @sg_instances[gn]
	           i = ig.size
	           ig[i-1] = instance_id
	        end
                @sg_active_instances[gn] = ig
             end
          end   

       @serverList= Array.new
       @serverState  = Array.new
       i=0
       j=0
       while i< @securityGrps.size
          if @sg_instances[@securityGrps[i]] == nil
             #puts  "#{@securityGrps[i]} no instances"
             @serverList[j] = @securityGrps[i]
             j=j+1
          else
             ia = @sg_instances[@securityGrps[i]]
             k=0
             while k < ia.size
                #puts "#{@securityGrps[i]} #{ia[k]}"
                r = @instances[ia[k]]
                if keypair=='' or keypair==r[:ssh_key_name]
                   @serverList[j] = @securityGrps[i]+"/"+ia[k]
                   @serverState[j] =  r[:aws_state]
                    j=j+1
                end
                k=k+1
             end
          end  
          i = i+1
       end
     
       if @serverList.size>0
          tree.expandTree(serverBranch)
       end
       i=0
       while i<@serverList.size
          if @serverList[i].index("/") != nil
             case @serverState[i]
                when "running"
                   tree.appendItem(serverBranch, @serverList[i], light, light)
                when  "shutting-down"
                   tree.appendItem(serverBranch, @serverList[i], disconnect, disconnect)
                when "pending"
                   tree.appendItem(serverBranch, @serverList[i], connect, connect)
                when "stopping","stopped"
                   tree.appendItem(serverBranch, @serverList[i], @stopped, @stopped)
                else
                   tree.appendItem(serverBranch, @serverList[i], nolight, nolight)
             end 
          else
             t = tree.appendItem(serverBranch, @serverList[i], doc, doc, @serverList[i])
          end
          i = i+1
       end
    end
    end
 end
 
 def refresh(instance_id)
     settings = @ec2_main.settings
     keypair = ""
     gi = ""
     s = ""
     if settings.get('KEYPAIR_NAME') != nil and settings.get('KEYPAIR_NAME').length>0
        keypair = settings.get('KEYPAIR_NAME')
     end
     ec2 = @ec2_main.environment.connection
     if ec2 != nil
        r = ec2.describe_instances([instance_id])
	i=0
	while i<r.length
	  x=r[i]
	  @instances[instance_id]=r[i]
          if x[:groups][0][:group_name] == nil
	     gn = x[:groups][0][:group_id]
	  else
	     gn = x[:groups][0][:group_name]
          end 
          ig = Array.new
          if @sg_instances[gn] == nil
             ig = Array.new
             ig[0]= instance_id
          else
             ig = @sg_instances[gn]
             i = ig.size
             ig[i] = instance_id
          end
          @sg_instances[gn] = ig
          if x[:aws_state] == "running"
             if @sg_active_instances[gn] == nil
 	        ig = Array.new
 	        ig[0]= instance_id
 	     else
 	        ig = @sg_instances[gn]
 	        i = ig.size
 	        ig[i-1] = instance_id
 	     end
 	     @sg_active_instances[gn] = ig
          end
          s = x[:aws_state]
	  if x[:groups][0][:group_name] == nil
	     gi = x[:groups][0][:group_id]
	  else
	     gi = x[:groups][0][:group_name]
          end 
          i = i+1
        end
        ec2.describe_addresses.each do |r|
          if r[:instance_id] == instance_id
             x = @instances[instance_id]
  	     x[:public_ip] = r[:public_ip]
  	     @instances[instance_id] = x
          end  
       end             
     end
     
     # refresh icon in tree.
     treeText =  gi + "/" + instance_id
     t = @tree.findItem(treeText)
     if t != nil 
      if t.text == treeText 
         case s  
            when "running"
	       if t.openIcon() != @light
                  t.setOpenIcon(@light)
                  t.setClosedIcon(@light)
                  @tree.updateItem(t)
               end             
	    when "shutting-down"
	       if t.openIcon() != @disconnect
                  t.setOpenIcon(@disconnect)
                  t.setClosedIcon(@disconnect)
                  @tree.updateItem(t)
               end	     
	    when "pending"
	       if t.openIcon() != @connect
                  t.setOpenIcon(@connect)
                  t.setClosedIcon(@connect)
                  @tree.updateItem(t)
               end
           when "stopping"
	       if t.openIcon() != @stopped
                  t.setOpenIcon(@stopped)
                  t.setClosedIcon(@stopped)
                  @tree.updateItem(t)
               end               
           when "stopped"
	       if t.openIcon() != @stopped
                  t.setOpenIcon(@stopped)
                  t.setClosedIcon(@stopped)
                  @tree.updateItem(t)
               end
	   else
	       if t.openIcon() != @nolight
                  t.setOpenIcon(@nolight)
                  t.setClosedIcon(@nolight)
                  @tree.updateItem(t)
               end
         end 
      end
     else 
        puts "tree item #{treeText} not found"
     end
 end 
 

 def securityGrps_Instances
        return @sg_instances
 end 
   
 def running(group)
       return @sg_instances[group]
 end
   
 def active(group)
         return @sg_active_instances[group]
 end
  
  def securityGrps
       return @securityGrps
  end
  
  def secGrps(group_name)
       if @secGrps[group_name] != nil 
          return @secGrps[group_name]
       else
          ec2 = @ec2_main.environment.connection
          if ec2 != nil
             if @ec2_main.settings.get("EC2_PLATFORM") != "openstack" 
                r = ec2.describe_security_groups(group_name, :describe_by => :group_name)
 	        i=0
	        while i<r.length
	           x=r[i]
	           @secGrps[x[:aws_group_name]]=r[i]
	           @ec2_main.treeCache.addSecGrp(group_name)
	           i = i+1
	        end
	     else
               @secGrps[group_name]={}
               @ec2_main.treeCache.addSecGrp(group_name)
              end
          else
          
          
          end
       end   
       return @secGrps[group_name]
  end 
  
  def refresh_secGrps(group_name)
      ec2 = @ec2_main.environment.connection
      if ec2 != nil and @ec2_main.settings.get("EC2_PLATFORM") != "openstack"
         r = ec2.describe_security_groups(group_name, :describe_by => :group_name)
   	 i=0
  	 while i<r.length
  	    x=r[i]
  	    @secGrps[x[:aws_group_name]]=r[i]
  	    i = i+1
         end
         return @secGrps[group_name]
      else
         return nil
      end   
  end
  
  def delete_secGrp(group_name)
       @securityGrps.delete(group_name)
       @secGrps.delete(group_name)
  end
  
  def addInstance(r)
      si = r[:aws_instance_id]
      if r[:groups][0][:group_name] == nil
         gi = r[:groups][0][:group_id]
      else
         gi = r[:groups][0][:group_name]
      end 
      @ec2_main.treeCache.addInstance(gi, si)
      @instances[si]=r
  end 
  
  
  
  def instances
       return @instances
  end 
  
  def instance(instance_id)
      return @instances[instance_id]
  end 
  
  def instance_names
     sa = Array.new
     i=0
     @instances.each do |key, r|
         if r[:groups][0][:group_name] == nil
	    gi = r[:groups][0][:group_id]
         else
            gi = r[:groups][0][:group_name]
         end   
         sa[i] = gi+"/"+key
         i=i+1
     end
     sa = sa.sort
     return sa
  end
  
  def instance_running_names
       sa = Array.new
       i=0
       @instances.each do |key, r|
           if r[:aws_state] != "terminated"
              if r[:groups][0][:group_name] == nil
	         gi = r[:groups][0][:group_id]
	      else
	         gi = r[:groups][0][:group_name]
              end 
              sa[i] = gi+"/"+key
              i=i+1
           end   
       end
       sa = sa.sort
       return sa
  end 
  
  def instance_group(i)
      gi = "" 
      if @instances.has_key?(i) == true 
         r = @instances[i]
         if @ec2_main.settings.get("EC2_PLATFORM") != "openstack"
            if r[:groups][0][:group_name] == nil
	       gi = r[:groups][0][:group_id]
	    else
	       gi = r[:groups][0][:group_name]
            end 
         else 
            gi = r.name
         end   
      end
      return gi
  end
  
  def instance_groups(i)
       gi = Array.new 
       if @instances.has_key?(i) == true 
           s = @instances[i]
           if @ec2_main.settings.get("EC2_PLATFORM") != "openstack"
              gp = s[:groups]
              gp.each do |g|
                if g[:group_name] == nil 
                   gi.push(g[:group_id])
                else
                   gi.push(g[:group_name])
                end   
              end
           else 
              gi[0] = s.name
           end
        end
        return gi
  end
  
  #
  # ops methods
  #
  def ops_refreshServerTree(tree, serverBranch, doc, light, nolight, connect, disconnect)
     puts "ServerCache.ops_refreshServerStackTree"
     conn = @ec2_main.environment.connection
     if conn != nil
        @securityGrps = Array.new
        i=0
        @ec2_main.serverCache.ops_secgrp.all.each do |r|
            @secGrps[r]={}
            @securityGrps[i] = r
            i = i+1
        end
        @securityGrps = @securityGrps.sort
        @instances = {}
        @serverList = Array.new
        @serverState = Array.new
        instance_id = ""
        j=0          
        conn.servers.each do |r|
             instance_id = r.id.to_s
             puts "server #{instance_id}"
             @instances[instance_id]=r 
             @serverList[j] = "#{r.name}/#{r.id}"
	     @serverState[j] =  r.state          
             j=j+1
        end
        i=0
        while i< @securityGrps.size 
           puts "Security Group #{@securityGrps[i]}" 
           @serverList[j] = @securityGrps[i]
           j=j+1
           i = i+1
        end
        puts "serverList #{@serverbList}"
        if @serverList.size>0
           tree.expandTree(serverBranch)
        end
        i=0
        while i<@serverList.size
          puts "Server #{@serverList[i]}  State #{@serverState[i]}"
          if @serverList[i].index("/") != nil
             case @serverState[i]
                when "ACTIVE"
                   tree.appendItem(serverBranch, @serverList[i], light, light)
                when  "shutting-down"
                   tree.appendItem(serverBranch, @serverList[i], disconnect, disconnect)
                when "BUILD"
                   tree.appendItem(serverBranch, @serverList[i], connect, connect)
                when "stopping","stopped"
                   tree.appendItem(serverBranch, @serverList[i], @stopped, @stopped)
                else
                   tree.appendItem(serverBranch, @serverList[i], nolight, nolight)
             end 
          else
             t = tree.appendItem(serverBranch, @serverList[i], doc, doc, @serverList[i])
          end
          i = i+1
        end
     end 
  end
  
 #        else 
 #           ec2.servers.each do |r|
 #            instance_id = r.id
 #            @instances[instance_id]=r
 #              gn = r[:groups][0][:name]
 #              if @sg_instances[gn] == nil
 #                 ig = Array.new
 #                 ig[0]= instance_id
 #              else
 #                 ig = @sg_instances[gn]
 #                 i = ig.size
 #                 ig[i] = instance_id
 #              end
 #              @sg_instances[gn] = ig
 #              # check this state
 #              if r[:state] == "running"
 #                 if @sg_active_instances[gn] == nil
 # 	           ig = Array.new
 # 	           ig[0]= instance_id
 # 	        else
 # 	           ig = @sg_instances[gn]
 # 	           i = ig.size
 # 	           ig[i-1] = instance_id
 # 	        end
 #                 @sg_active_instances[gn] = ig
 #              end         
 #           end
 #      end 
       
  
  #
  # rds methods
  #
  def refreshDBTree(tree, dbBranch, doc, database, nolight, connect, disconnect)
       puts "ServerCache.refreshDBTree"
       settings = @ec2_main.settings
       rds = @ec2_main.environment.rds_connection
       if rds != nil
          @db_Security_Grps = Array.new
          i=0
          begin
             rds.describe_db_security_groups.each do |r|
                @db_secGrps[r[:name]]=r
                @db_Security_Grps[i] = r[:name]
                i = i+1
             end
          rescue 
   	   puts "***Error on connection to RDS - check your keys in ServerCache.refreshDBTree"
             error_message("RDS Connection Error",$!.to_s+" - check your RDS Access Setting")
             return
          end 
          @db_Security_Grps = @db_Security_Grps.sort
          puts @db_Security_Grps
          @db_instances = {}
          @dbList = Array.new
          @dbState = Array.new
          j=0          
          rds.describe_db_instances.each do |r|
               db_instance_id = r[:aws_id]
               puts "db i #{db_instance_id}"
               @db_instances[db_instance_id]=r 
               @dbList[j] = "DBInstance/"+r[:aws_id]
	       @dbState[j] =  r[:status]          
               j=j+1
          end
          i=0
          while i< @db_Security_Grps.size
             @dbList[j] = @db_Security_Grps[i]
             j=j+1
             i = i+1
          end
          puts "dbList #{@dbList}"
          if @dbList.size>0
             tree.expandTree(dbBranch)
          end
          i=0
          while i<@dbList.size
             if @dbList[i].index("/") != nil
               case  @dbState[i]
                when "available"
                   tree.appendItem(dbBranch, @dbList[i], database, database)
                when "deleting"
                   tree.appendItem(dbBranch, @dbList[i], disconnect, disconnect)
                when "deleted"
                   tree.appendItem(dbBranch, @dbList[i], nolight, nolight)
                when "failed"
                   tree.appendItem(dbBranch, @dbList[i], @cross, @cross)
                when "creating"    
                   tree.appendItem(dbBranch, @dbList[i], connect, connect)
                when "modifying"
                   tree.appendItem(dbBranch, @dbList[i], @link_break, @link_break)
                when "resetting-master-credentials"
                   tree.appendItem(dbBranch, @dbList[i], @link_break, @link_break)
                when "rebooting"
                   tree.appendItem(dbBranch, @dbList[i], @reboot, @reboot)
               end
             else
                tree.appendItem(dbBranch, @dbList[i], doc, doc)
             end
             i = i+1
          end
       end 
  end
  
  def db_security_grps
     return  @db_Security_Grps
  end   
 
 def delete_db_secGrp(group_name)
         @db_Security_Grps.delete(group_name)
         @db_secGrps.delete(group_name)
  end
  
  def db_instances
         return @db_instances
  end 
  
  def addDBInstance(r)
          si = r[:aws_id]
          @ec2_main.treeCache.addDBInstance(si)
          @db_instances[si]=r
  end 
  
  def rds_refresh(instance_id)
     settings = @ec2_main.settings
     s = "deleted"
     r = nil
     rds = @ec2_main.environment.rds_connection
     if rds != nil
        begin
          r = rds.describe_db_instances([instance_id])
          i=0
  	  while i<r.length
  	     x=r[i]
   	     @db_instances[instance_id]=r[i]
  	     s = x[:status]
   	     i = i+1
          end          
        rescue
          @db_instances[instance_id] = nil
          s = "deleted"
        end

     end
       
       # refresh icon in tree.
       # this need to be made independent of server tree
       treeText =  "DBInstance/" + instance_id
       t = @tree.findItem(treeText)
       if t != nil 
         if t.text == treeText
              if s == "available"
  	         if t.openIcon() != @database
                   t.setOpenIcon(@database)
                   t.setClosedIcon(@database)
                   @tree.updateItem(t)
                 end
              end   
  	      if s ==  "deleting"
  	          if t.openIcon() != @disconnect
                     t.setOpenIcon(@disconnect)
                     t.setClosedIcon(@disconnect)
                     @tree.updateItem(t)
                  end
              end    
  	      if s ==  "deleted"
  	            if t.openIcon() != @nolight
                       t.setOpenIcon(@nolight)
                       t.setClosedIcon(@nolight)
                       @tree.updateItem(t)
                    end
              end      
   	      if s ==  "failed"
  	            if t.openIcon() != @cross
                       t.setOpenIcon(@cross)
                       t.setClosedIcon(@cross)
                       @tree.updateItem(t)
                    end
              end      
  	      if s ==  "creating"
  	            if t.openIcon() != @connect
                      t.setOpenIcon(@connect)
                      t.setClosedIcon(@connect)
                      @tree.updateItem(t)
                    end
              end      
    	      if s ==  "modifying"
   	            if t.openIcon() != @link_break
                       t.setOpenIcon(@link_break)
                       t.setClosedIcon(@link_break)
                       @tree.updateItem(t)
                    end
              end      
    	      if s ==  "resetting-master-credentials"
   	            if t.openIcon() != @link_break
                       t.setOpenIcon(@link_break)
                       t.setClosedIcon(@link_break)
                       @tree.updateItem(t)
                    end
              end      
   	      if s ==  "rebooting"
   	            if t.openIcon() != @reboot
                       t.setOpenIcon(@reboot)
                       t.setClosedIcon(@reboot)
                       @tree.updateItem(t)
                    end
              end      
         end          
       else 
         puts "tree item #{treeText} not found"
       end
  end
 
  
  def DBInstance(instance_id)
        return @db_instances[instance_id]
  end 
  
  def db_secGrps(group_name)
         if @db_secGrps[group_name] != nil
            return @db_secGrps[group_name]
         else
            rds = @ec2_main.environment.rds_connection
            if rds != nil
               r = rds.describe_db_security_groups([group_name])
   	       i=0
  	       while i<r.length
  	          x=r[i]
  	          #puts group_name
  	          @db_secGrps[x[:name]]=r[i]
  	          @ec2_main.treeCache.addDBSecGrp(group_name)
  	          i = i+1
               end
            end
            return @db_secGrps[group_name]
         end
  end 
  
  def refresh_db_secGrps(group_name)
      rds = @ec2_main.environment.rds_connection
      if rds != nil
         r = rds.describe_db_security_groups([group_name])
     	 i=0
    	 while i<r.length
    	    x=r[i]
    	    #puts group_name
    	    @db_secGrps[x[:name]]=r[i]
    	    i = i+1
         end
         return @db_secGrps[group_name]
      else   
         return nil
      end   
  end 
  
  def ops_secgrp
       @ops_secgrp
  end 
  
  def error_message(title,message)
        FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
 

end