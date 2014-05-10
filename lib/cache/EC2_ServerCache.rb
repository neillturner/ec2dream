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
        @serverList= []
        @sg_active_instances = {}
        @securityGrps = []
        @secGrps = {}
        @secGrps_tags = {}
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
        @vpc_serverList= {}
        @vpc_securityGrps = {}
        @vpc_secGrps = {}
        @vpc_instances = {}
        @vpc_sg_instances = {}
        @vpc_sg_active_instances = {}
end

def refreshVpcServerTree(tree, serverBranch, doc, light, nolight, connect, disconnect, vpc)
    settings = @ec2_main.settings
    if settings.cloudfoundry
       refreshCfyTree(tree, serverBranch, doc, light, nolight, connect, disconnect)
    else
       puts "ServerCache.refreshVpcServerTree"
       @vpc_serverList[vpc]= {}
       #@vpc_securityGrps[vpc] = []
       #@vpc_secGrps[vpc] = {}
       #eip = {}
       #@ec2_main.environment.security_group.all('vpc-id'=>vpc).each do |r|
       #   gp = r[:aws_group_name]
       #   if gp != nil and gp != ""
       #      @vpc_secGrps[vpc][gp]=r
       #      @vpc_securityGrps[vpc].push(gp)
       #   end
       #end
       #@ec2_main.environment.addresses.all.each do |r|
       #   if r[:instance_id] != nil and r[:instance_id] != ""
       #      eip[r[:instance_id]] = r[:public_ip]
       #   end
       #end
       @vpc_securityGrps[vpc] = @vpc_securityGrps[vpc].sort_by { |x| x.downcase }
       i=0
       @vpc_securityGrps[vpc].each do |s|
          @vpc_serverList[vpc][s] = []
          i=i+1
       end
       @vpc_instances[vpc] = {}
       @vpc_sg_instances[vpc] = {}
       @vpc_sg_active_instances[vpc] = {}
       i=0
       @ec2_main.environment.servers.all([],{'vpc-id'=>vpc}).each do |r|
         instance_id = r[:aws_instance_id]
         if @eip[instance_id] != nil
           r[:public_ip] = @eip[instance_id]
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
	    @vpc_serverList[vpc][gn].push("#{r['name']}/#{instance_id}")
	 rescue
	    puts "ERROR: mismatch on security groups"
	 end
        @vpc_instances[vpc][instance_id]=r
        if @vpc_sg_instances[vpc][gn] == nil
            ig = Array.new
            ig[0]= instance_id
         else
            ig = @vpc_sg_instances[vpc][gn]
            i = ig.size
            ig[i] = instance_id
         end
         @vpc_sg_instances[vpc][gn] = ig
         if r[:aws_state] == "running" or r[:aws_state] == "ACTIVE"
            if @vpc_sg_active_instances[vpc][gn] == nil
	       ig = Array.new
	       ig[0]= instance_id
	    else
	       ig = @vpc_sg_instances[vpc][gn]
	       i = ig.size
	       ig[i-1] = instance_id
	    end
            @vpc_sg_active_instances[vpc][gn] = ig
         end
      end
      @vpc_securityGrps[vpc].each do |s|
         if @vpc_serverList[vpc][s].size>0
            @vpc_serverList[vpc][s] = @vpc_serverList[vpc][s].sort_by { |x| x.downcase }
         end
      end
      i=0
      #puts "*** vpc_securityGrps #{@vpc_securityGrps[vpc]}"
      while i< @vpc_securityGrps[vpc].size
         groupBranch = tree.appendItem(serverBranch, @vpc_securityGrps[vpc][i], @firewall, @firewall, @vpc_securityGrps[vpc][i])
         if @vpc_serverList[vpc][@vpc_securityGrps[vpc][i]].size>0
            tree.expandTree(groupBranch)
            @vpc_serverList[vpc][@vpc_securityGrps[vpc][i]].each do |s|
              instance_id = s
              sa = s.split"/"
	      instance_id = sa.last if sa.size>1
	      r=@vpc_instances[vpc][instance_id]
	      state = ""
	      if r != nil
	         state = r[:aws_state]
	      end
              case state
                   when "running","ACTIVE","RUNNING"
                      tree.appendItem(groupBranch, s, light, light)
                   when  "shutting-down","ACTIVE(deleting)","STOPPING"
                      tree.appendItem(groupBranch, s, disconnect, disconnect)
                   when "pending","BUILD","BUILD(scheduling)","BUILD(spawning)","REBOOT","RESIZE","REVERT_RESIZE","HARD_REBOOT","PROVISIONING","STAGING"
                      tree.appendItem(groupBranch, s, connect, connect)
                   when "stopping","stopped","DELETED","SHUTOFF","ERROR","SUSPENDED","VERIFY_RESIZE","TERMINATED","STOPPED"
                      tree.appendItem(groupBranch, s, @stopped, @stopped)
                   else
                      tree.appendItem(groupBranch, s, nolight, nolight)
              end
            end
          end
          i = i+1
       end
       if @vpc_securityGrps[vpc].size>0
          tree.expandTree(serverBranch)
       end
    end
 end

 def refreshServerTree(tree, serverBranch, doc, light, nolight, connect, disconnect)
     settings = @ec2_main.settings
     if settings.cloudfoundry
        refreshCfyTree(tree, serverBranch, doc, light, nolight, connect, disconnect)
     else
        puts "ServerCache.refreshServerTree"
        @serverList= {}
        @securityGrps = []
        @secGrps = {}

        @vpc_securityGrps = {}
        @vpc_secGrps = {}
        @eip = {}
        load_secGrps_tags
        @ec2_main.environment.security_group.all.each do |r|
            if r['groupId'] != nil
                r['tagSet'] =  @secGrps_tags[r['groupId']]
            end
            gp = r[:aws_group_name]
            if gp != nil and gp != ""
              if (r['vpcId'] == nil or r['vpcId']=="")
                  @secGrps[gp]=r
                  @securityGrps.push(gp)
              else
                  vpc = r['vpcId']
                  @vpc_securityGrps[vpc] = [] if @vpc_securityGrps[vpc] == nil
                  @vpc_secGrps[vpc] = {}      if  @vpc_secGrps[vpc] == nil
 	          @vpc_secGrps[vpc][gp]=r
	          @vpc_securityGrps[vpc].push(gp)
              end

           end
        end
        @ec2_main.environment.addresses.all.each do |r|
           if r[:instance_id] != nil and r[:instance_id] != ""
              @eip[r[:instance_id]] = r[:public_ip]
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
            if r['vpcId'] == nil or r['vpcId']==""
              instance_id = r[:aws_instance_id]
              if @eip[instance_id] != nil
                 r[:public_ip] = @eip[instance_id]
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
                    when "running","ACTIVE","RUNNING"
                         tree.appendItem(groupBranch, s, light, light)
                    when  "shutting-down","ACTIVE(deleting)","STOPPING"
                         tree.appendItem(groupBranch, s, disconnect, disconnect)
                    when "pending","BUILD","BUILD(scheduling)","BUILD(spawning)","REBOOT","RESIZE","REVERT_RESIZE","HARD_REBOOT","PROVISIONING","STAGING"
                         tree.appendItem(groupBranch, s, connect, connect)
                    when "stopping","stopped","DELETED","SHUTOFF","ERROR","SUSPENDED","VERIFY_RESIZE","TERMINATED","STOPPED"
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
       else
        puts "refreshing instance not found #{instance_id}"
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
        when "running","ACTIVE","RUNNING"
               updateIcon(t,@light)
	    when "shutting-down","ACTIVE(deleting)","STOPPING"
	       updateIcon(t,@disconnect)
	    when "pending","BUILD","BUILD(scheduling)","BUILD(spawning)","REBOOT","RESIZE","REVERT_RESIZE","HARD_REBOOT","ACTIVE(rebooting)","PROVISIONING","STAGING"
	       updateIcon(t,@connect)
           when "stopping","stopped","SUSPENDED","VERIFY_RESIZE","TERMINATED","STOPPED"
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

 def securityGrps_Instances(vpc=nil)
     if vpc != nil
        return @vpc_sg_instances[vpc]
     else
        return @sg_instances
     end
 end

 # TO DO for VPC - i don't think these are used anymore
 #def running(group)
 #      return @sg_instances[group]
 #end

 # TO DO for VPC  - i don't think these are used anymore
 #def active(group)
 #        return @sg_active_instances[group]
 #end

  # TO DO for VPC - used by treecache  ??? cannot find
  #def securityGrps
  #     return @securityGrps
 # end

  # DONE - add part for vpc.
  def secGrps(group_name,vpc=nil)
       puts "ServerCache.secGrps(#{group_name},#{vpc})"
      if vpc == nil or vpc == ""
           if @secGrps[group_name] != nil and
             return @secGrps[group_name]
          else
	     i=0
	     load_secGrps_tags
	     @ec2_main.environment.security_group.all.each do |r|
               if r[:aws_group_name] == group_name and (r['vpcId']=nil or r['vpcId']=="")
	           if r['groupId'] != nil
                      r['tagSet'] =  @secGrps_tags[r['groupId']]
                   end
	           @secGrps[r[:aws_group_name]]=r
	           @ec2_main.treeCache.addSecGrp(group_name)
	        end
	     end
          end
          return @secGrps[group_name]
       else
          if @vpc_secGrps[vpc][group_name] != nil
             return @vpc_secGrps[vpc][group_name]
          else
	     i=0
	     load_secGrps_tags
	     @ec2_main.environment.security_group.all({'vpc-id'=>vpc}).each do |r|
                if r[:aws_group_name] == group_name
	           if r['groupId'] != nil
                      r['tagSet'] =  @secGrps_tags[r['groupId']]
                   end
                   @vpc_secGrps[vpc][r[:aws_group_name]]=r
	           # TO DO
	           #@ec2_main.treeCache.addSecGrp(group_name)
	        end
	     end
          end
          return @vpc_secGrps[vpc][group_name]
       end
  end

  # DONE - need to add vpc parameter used by ec2_secgrp
  def refresh_secGrps(group_name, vpc=nil)
    puts "ServerCache.refresh_secGrps(#{group_name},#{vpc})"
    filter = nil
    filter = {'vpc-id' => vpc}  if vpc != nil and vpc !=""
    load_secGrps_tags
    if filter == nil
       @ec2_main.environment.security_group.all.each do |r|
          if r[:aws_group_name] == group_name and (r['vpcId']==nil or r['vpcId']=="")
	     if r['groupId'] != nil
                r['tagSet'] =  @secGrps_tags[r['groupId']]
             end
	     @secGrps[r[:aws_group_name]]=r
          end
       end
       return @secGrps[group_name]
    else
       @ec2_main.environment.security_group.all(filter).each do |r|
           if r[:aws_group_name] == group_name
             if r['groupId'] != nil
                r['tagSet'] =  @secGrps_tags[r['groupId']]
             end
	     @vpc_secGrps[vpc][r[:aws_group_name]]=r
          end
       end
       return @vpc_secGrps[vpc][group_name]
    end
  end

  def delete_secGrp(group_name,vpc)
     if vpc == nil or vpc == ""
       @securityGrps.delete(group_name)
       @secGrps.delete(group_name)
     else
       @vpc_securityGrps[vpc].delete(group_name)
       @vpc_secGrps[vpc].delete(group_name)
     end
  end

  def load_secGrps_tags
     puts "SecGrps.load_secGrps_tags"
     @secGrps_tags = {}
     @ec2_main.environment.tags.all(nil,'security-group').each do |r|
            @secGrps_tags[r['resourceId']] = {} if @secGrps_tags[r['resourceId']] == nil
            @secGrps_tags[r['resourceId']][r['key']] = r['value']
     end
  end

  # DONE - can figure out vpc from r['vpcId']
  def addInstance(r)
     puts "adding instance name #{r['name']}"
     si = r[:aws_instance_id]
     vpc = r['vpcId']
     gi = group_name(r)
    	  ta = {}
    	  if r['tagSet'] != nil
    	    ta = r['tagSet']
    	  end
    	  nickname = nil
          if r['name'] == nil or r['name'] == ""
             t = EC2_ResourceTags.new(@ec2_main,ta,nil)
	     nickname = t.nickname
	     if nickname != nil and nickname != ""
	        r['name'] = nickname
	     else
	        r['name']=""
	        if gi != nil
	           r['name']=gi
	        else
	           r['name']='default'
	        end
            end
	  end

     if r['name'] != nil and r['name'] != ""
        gi = r['name']
     end
     if gi != nil
         puts "adding #{gi}/#{si} in vpc #{vpc} to tree"
        @ec2_main.treeCache.addInstance(gi, si, vpc)
     end
     @instances[si]=r
  end

  # TO DO for VPC - merge vpc instances - i don't think it is used anymore
  #def instances
  #     return @instances
  #end

  def instance(instance_id)
      return @instances[instance_id] if @instances[instance_id] != nil
      @vpc_instances.each  do |k,v|
         if v.has_key?(instance_id) == true
      	    return v[instance_id]
         end
      end
      return nil
  end

  def instance_names
     sa = []
     @instances.each do |key, r|
         gi = group_name(r)
         if r['name'] != nil
            gi = r['name']
         end
         if gi != nil
            sa.push(gi+"/"+key)
         else
            sa.push(key)
         end
     end
     @vpc_instances.each  do |k,v|
       v.each do |key, r|
         gi = group_name(r)
         if r['name'] != nil
            gi = r['name']
         end
         if gi != nil
            sa.push(gi+"/"+key)
         else
            sa.push(key)
         end
       end
     end
     sa = sa.sort
     return sa
  end

  # DONE
  def instance_running_names(type=nil)
    sa = []
    if type==nil or type != "vpc"
      sa = running_names(@instances)
    else
      @vpc_instances.each do |vpc, inst|
         sa += running_names(inst)
      end
    end
    return sa
  end

  def running_names(cache)
       sa = Array.new
       i=0
       cache.each do |key, r|
	     puts "**** aws_state #{r[:aws_state]}"
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
            @vpc_instances.each  do |k,v|
                if v.has_key?(i) == true
	           r = v[i]
                   gi = group_name(r)
                 end
             end
         end
         puts "ERROR: No Security Group for instances #{i}" if gi == ""
         return gi
  end

  def instance_group(i)
       gi = ""
       if @instances.has_key?(i) == true
          s = @instances[i]
       else
          @vpc_instances.each  do |k,v|
             s = v[i] if v.has_key?(i) == true
          end
       end
       if s != nil
         gi = group_name(s)
         if s['name'] != nil
            gi = s['name']
         end
       end
       return gi
  end

  def instance_groups(i)
       gi = []
       s = nil
       if @instances.has_key?(i) == true
          s = @instances[i]
       else
          @vpc_instances.each  do |k,v|
             s = v[i] if v.has_key?(i) == true
          end
       end
       if s != nil
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