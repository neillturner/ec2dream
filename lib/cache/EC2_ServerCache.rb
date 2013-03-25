require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

class EC2_ServerCache 

def initialize(owner, tree)
        @ec2_main = owner
        @tree = tree
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
	@firewall = @ec2_main.makeIcon("firewall.png")
	@firewall.create
end  

def refreshServerTree(tree, serverBranch, doc, light, nolight, connect, disconnect)
    settings = @ec2_main.settings
    if settings.cloudfoundry 
       refreshCfyTree(tree, serverBranch, doc, light, nolight, connect, disconnect)
    else 
       puts "ServerCache.refreshServerTree"
       @serverList= {}
       @securityGrps = []
       eip = {}
       @ec2_main.environment.security_group.all.each do |r|
          gp = r[:aws_group_name]
          if gp != nil and gp != ""
             @secGrps[gp]=r
             @securityGrps.push(gp)
          end   
       end
       @ec2_main.environment.addresses.all.each do |r|
          if r[:instance_id] != nil and r[:instance_id] != ""
             eip[r[:instance_id]] = r[:public_ip]
          end
       end
       @securityGrps = @securityGrps.sort_by { |x| x.downcase }
       i=0
       @securityGrps.each do |s|
          @serverList[s] = []
          i=i+1
       end
       @instances = {}
       @sg_instances = {}
       @sg_active_instances = {}
       #@tags_filter= @ec2_main.settings.load_filter()
       i=0
       @ec2_main.environment.servers.all.each do |r|
         instance_id = r[:aws_instance_id]
         if eip[instance_id] != nil
           r[:public_ip] = eip[instance_id]
         end 
         gn = group_name(r)
         if r['name'] == nil or r['name'] == ""
    	     ta = r['tagSet']
    	     nickname = nil
    	     if ta.size>0
   	        t = EC2_ResourceTags.new(@ec2_main,ta,nil)
	        nickname = t.nickname
	     end   
	     if nickname != nil and nickname != ""
	        r['name'] = nickname
	     else
	        r['name']=""
	        if gn != nil
	           r['name']=gn
	        else
	           r['name']='default'
	       end   
            end 
	 end 
	 begin 
	    @serverList[gn].push("#{r['name']}/#{instance_id}")
	 rescue
	    puts "ERROR: mismatch on security groups"
	 end  
        @instances[instance_id]=r
        if @sg_instances[gn] == nil
            ig = Array.new
            ig[0]= instance_id
         else
            ig = @sg_instances[gn]
            i = ig.size
            ig[i] = instance_id
         end
         @sg_instances[gn] = ig
         if r[:aws_state] == "running" or r[:aws_state] == "ACTIVE"
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
      @securityGrps.each do |s|
         if @serverList[s].size>0
            @serverList[s] = @serverList[s].sort_by { |x| x.downcase }
         end
      end 
      i=0
      while i< @securityGrps.size
         groupBranch = tree.appendItem(serverBranch, @securityGrps[i], @firewall, @firewall, @securityGrps[i])
         if @serverList[@securityGrps[i]].size>0
            tree.expandTree(groupBranch)
            @serverList[@securityGrps[i]].each do |s|
              instance_id = s
              sa = s.split"/"
	      instance_id = sa.last if sa.size>1
	      r=@instances[instance_id]
	      state = ""
	      if r != nil
	         state = r[:aws_state]
	      end
              case state 
                   when "running","ACTIVE"
                      tree.appendItem(groupBranch, s, light, light)
                   when  "shutting-down"
                      tree.appendItem(groupBranch, s, disconnect, disconnect)
                   when "pending","BUILD","BUILD(scheduling)","BUILD(spawning)","REBOOT","RESIZE","REVERT_RESIZE","HARD_REBOOT"
                      tree.appendItem(groupBranch, s, connect, connect)
                   when "stopping","stopped","DELETED","SHUTOFF","ERROR","SUSPENDED","VERIFY_RESIZE"
                      tree.appendItem(groupBranch, s, @stopped, @stopped)
                   else
                      tree.appendItem(groupBranch, s, nolight, nolight)
              end                 
            end
          end
          i = i+1
       end
       if @securityGrps.size>0
          tree.expandTree(serverBranch)
       end
    end
 end
 
 
 
 def refresh(instance_id)
     settings = @ec2_main.settings
     gi = ""
     s = ""
     r = @ec2_main.environment.servers.all([instance_id])
     @ec2_main.environment.servers.all([instance_id]).each do |x|
       if x[:aws_instance_id]=instance_id
          puts "refreshing instance found #{instance_id}"
          gn = group_name(x)
    	  ta = {}
    	  if x['tagSet'] != nil
    	    ta = x['tagSet']
    	  end
    	  nickname = nil          
          if x['name'] == nil or x['name'] == ""
             t = EC2_ResourceTags.new(@ec2_main,ta,nil)
	     nickname = t.nickname
	     if nickname != nil and nickname != ""
	        x['name'] = nickname
	     else
	        x['name']=""
	        if gn != nil
	           x['name']=gn
	        else
	           x['name']='default'
	        end   
            end 
	  end           
	  @instances[instance_id]=x
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
          puts "refresh state #{ x[:aws_state]}" 
          if x[:aws_state] == "running"	or x[:aws_state] == "ACTIVE"
             if @sg_active_instances[gn] == nil
 	        ig = Array.new
 	        ig[0]= instance_id
 	     else
 	        ig = @sg_instances[gn]
 	        i = ig.size
 	        ig[i-1] = instance_id
 	     end
 	     puts "active instances #{gn} #{ig}"  
 	     @sg_active_instances[gn] = ig
          end
          s = x[:aws_state]
          gi = group_name(x)
          if x['name'] != nil 
             gi = x['name']
          end
       end   
     end
     @ec2_main.environment.addresses.all.each do |r|
          if r[:instance_id] == instance_id
             x = @instances[instance_id]
  	     x[:public_ip] = r[:public_ip]
  	     @instances[instance_id] = x
          end
     end
     
     # refresh icon in tree.
     treeText =  gi + "/" + instance_id
     puts "refresh #{treeText}"
     t = @tree.findItem(treeText)
     if t != nil 
      if t.text == treeText
          puts "tree item #{treeText} found updating state #{s}"
         case s  
            when "running","ACTIVE"
               updateIcon(t,@light)
	    when "shutting-down","ACTIVE(deleting)"
	       updateIcon(t,@disconnect)
	    when "pending","BUILD","BUILD(scheduling)","BUILD(spawning)","REBOOT","RESIZE","REVERT_RESIZE","HARD_REBOOT","ACTIVE(rebooting)"
	       updateIcon(t,@connect)
           when "stopping","stopped","SUSPENDED","VERIFY_RESIZE"
	       updateIcon(t,@stopped)
	   else
	       if s.start_with?('ACTIVE')
	          updateIcon(t,@light)
	       else
	          updateIcon(t,@nolight)
               end
         end 
      end
     else 
        puts "tree item #{treeText} not found - refrshing tree"
        @ec2_main.treeCache.refresh
     end
 end
 
 def group_name(x)
   gn = ""
   begin
    if x['groupSet'] != nil 
       gn = x['groupSet'][0]
    elsif x[:sec_groups].instance_of? Array and x[:sec_groups][0] != nil
       gn = x[:sec_groups][0]
    elsif x['security_groups'].instance_of? Array and  x['security_groups'][0] != nil
       gn = x['security_groups'][0]['name']
    elsif x[:groups].instance_of? Array and x[:groups][0][:group_name] == nil
       gn = x[:groups][0][:group_id]
    else
       gn = x[:groups][0][:group_name]
    end
   rescue
   end
   if gn == nil or gn == ""
     gn = "default"
   end
   return gn
 end
 
 def updateIcon(t,icon)
    if t.openIcon() != icon
       t.setOpenIcon(icon)
       t.setClosedIcon(icon)
       @tree.updateItem(t)
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
       puts "ServerCache.secGrps(#{group_name})"
       if @secGrps[group_name] != nil
          return @secGrps[group_name]
       else
	  i=0 
	  @ec2_main.environment.security_group.all.each do |r|
             if r[:aws_group_name] == group_name
	        @secGrps[r[:aws_group_name]]=r
	        @ec2_main.treeCache.addSecGrp(group_name)
	     end
	  end
       end   
       return @secGrps[group_name]
  end 
  
  def refresh_secGrps(group_name)
    i=0 
    r = @ec2_main.environment.security_group.all.each do |r|
       if r[:aws_group_name] == group_name
	  @secGrps[r[:aws_group_name]]=r
       end 
    end      
    return @secGrps[group_name]
  end
  
  def delete_secGrp(group_name)
       @securityGrps.delete(group_name)
       @secGrps.delete(group_name)
  end
  
  def addInstance(r)
     puts "adding instance #{r}  name #{r['name']}"
     si = r[:aws_instance_id]
     gi = group_name(r)
     if r['name'] != nil and r['name'] != "" 
        gi = r['name']
     end 
     if gi != nil 
         puts "adding #{gi}/#{si}" 
        @ec2_main.treeCache.addInstance(gi, si)
     end   
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
         gi = group_name(r)
         if r['name'] != nil
            gi = r['name']
         end   
         if gi != nil 
            sa[i] = gi+"/"+key
         else
            sa[i] = key
         end 
         i=i+1
     end
     sa = sa.sort
     return sa
  end

  def instance_running_names
     sa = Array.new
     i=0
     @instances.each do |key, r|
       if (@ec2_main.settings.openstack and r[:aws_state] == "ACTIVE") or (!@ec2_main.settings.openstack and r[:aws_state] != "terminated") 
         gi = group_name(r)
         if r['name'] != nil
            gi = r['name']
         end   
         if gi != nil 
            sa[i] = gi+"/"+key
         else
            sa[i] = key
         end 
         i=i+1
       end 
     end
     sa = sa.sort
     return sa
  end
  
  def instance_sec_group(i)
        if !@ec2_main.settings.openstack
          i="i-#{i}"
        end  
        gi = ""
         if @instances.has_key?(i) == true
           r = @instances[i]
           gi = group_name(r)
         else 
           puts "ERROR: No Security Group for instances #{i}"
         end  
         return gi
  end

  def instance_group(i)
      gi = ""
       if @instances.has_key?(i) == true
         r = @instances[i]
         gi = group_name(r)
         if r['name'] != nil         
            gi = r['name']         
         end
       end  
       return gi
  end
  
  def instance_groups(i)
       gi = [] 
       if @instances.has_key?(i) == true
           s = @instances[i]
           if s['name'] != nil and @ec2_main.settings.openstack
              gi[0] = s['name']
           elsif s[:groups].instance_of?(Array)
              gp = s[:groups]
              gp.each do |g|
                if g[:group_name] == nil 
                   gi.push(g[:group_id])
                else
                  gi.push(g[:group_name])
                end
              end   
           elsif s[:sec_groups].instance_of?(Array)
              s[:sec_groups].each do |g|
                 gi.push(g)
              end
           elsif s['groupSet'].instance_of?(Array)   
             gi=s['groupSet'] 
           end   
        end
        return gi
  end
  
  def instance_groups_list(i)
      gp = instance_groups(i) 
      puts "instance_groups_list instance #{i} group #{gp}"
      gp_list = ""
      gp.each do |g|
         if gp_list.length>0
      	    gp_list = gp_list+","+g
         else
      	    gp_list = g
         end 
     end
     return gp_list
  end
  
  def instance_groups_first(i)
      gp = instance_groups(i)  
      gp_first = ""
      gp.each do |g|
         if gp_first == ""
      	    gp_first = g
         end 
     end
     return gp_first 
  end   
  
  #
  # cloudfoundry methods
  #
  
  def refreshCfyTree(tree, serverBranch, doc, light, nolight, connect, disconnect)
            settings = @ec2_main.settings
            puts "ServerCache.refreshCfyTree"
            @serverList= Array.new
            @serverState  = Array.new       
            @securityGrps = Array.new
            @instances = {}
            @sg_instances = {}
            @sg_active_instances = {}
            @profile_folder = "launch"        
            begin
               items = Dir.entries(@ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder)
            rescue
               error_message("Repository Location does not exist",$!)
               return
            end    
            if items != nil
               items.each do |e|
                  e = e.to_s
                  if e != "." and e != ".." and e != ".properties"
                     sa = e.split"."
   	             if sa.size>1 and sa[1] == "properties"
	                @securityGrps.push(sa[0])
    	             end
                   end 
               end
            end            
            @ec2_main.environment.cfy_app.find_all_apps().each do |r|
              k = "#{r[:name]}/#{r[:staging][:model]}" 
              @serverList.push(k)
              @serverState.push(r[:state])
              @instances[k]=r
              if @sg_instances["#{r[:name]}"] == nil 
                 @sg_instances["#{r[:name]}"]=Array.new
              end   
              @sg_instances["#{r[:name]}"].push(r) 
            end   

            i=0
            while i<@serverList.size
               if @serverList[i].index("/") != nil
                  case @serverState[i]
                     when "RUNNING","STARTED"
                        tree.appendItem(serverBranch, @serverList[i], light, light)
                     when "FLAPPING"
                        tree.appendItem(serverBranch, @serverList[i], disconnect, disconnect)
                     when "STARTING"
                        tree.appendItem(serverBranch, @serverList[i], connect, connect)
                     when "STOPPED","DOWN"
                        tree.appendItem(serverBranch, @serverList[i], @stopped, @stopped)
                     else
                        tree.appendItem(serverBranch, @serverList[i], nolight, nolight)
                  end 
               else
                  tree.appendItem(serverBranch, @serverList[i], doc, doc, @serverList[i])
               end
               i = i+1
            end
            i=0
            while i<@securityGrps.size
               if @sg_instances[@securityGrps[i]]==nil
                  tree.appendItem(serverBranch, @securityGrps[i], doc, doc, @securityGrps[i])
               end   
               i = i+1
            end
            if @serverList.size>0 or @securityGrps.size>0
               tree.expandTree(serverBranch)
            end            
 end

end