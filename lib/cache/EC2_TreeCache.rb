
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

require 'cache/EC2_ServerCache'

class EC2_TreeCache 

def initialize(owner, tree)
        @ec2_main = owner
        @tree = tree
        @ec2 = nil
        @mon = nil
        @s3 = nil
        @rds = nil
        @tree_lock = Mutex.new
        @status = "empty"
        # Construct some icons we'll use
        @folder_open   = @ec2_main.makeIcon("application_view_icons.png")
	@folder_open.create
	@folder_closed = @ec2_main.makeIcon("folder.png")
	@folder_closed.create
	@doc           = @ec2_main.makeIcon("doc_text_image.png")
	@doc.create
	@doc_script    = @ec2_main.makeIcon("doc_page.png")
	@doc_script.create
	@doc_settings  = @ec2_main.makeIcon("doc_tag.png")
	@doc_settings.create
	@light 	   = @ec2_main.makeIcon("server.png")
	@light.create
	@nolight 	   = @ec2_main.makeIcon("stop.png")
	@nolight.create
	@parallel 	   = @ec2_main.makeIcon("rocket.png")
        @parallel.create
	@paralleldb 	   = @ec2_main.makeIcon("rocketdb.png")
        @paralleldb.create        
        @lock    = @ec2_main.makeIcon("lock.png")
	@lock.create
	@online    = @ec2_main.makeIcon("status_online.png")
	@online.create
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
	@topmost_text = ""
	
end  


  def load(env)
     @env = env
     platform = @ec2_main.settings.get("EC2_PLATFORM")
     if @topmost.class  == Fox::FXTreeItem and @topmost.text != "Loading......"
	#tr=Thread.new do
	   @status = "loading"
           @tree.clearItems
           @topmost = @tree.appendItem(nil, "Loading......", @online, @online)
           @tree.expandTree(@topmost)
           @tree.appendItem(@topmost, "Settings", @doc_settings, @doc_settings)
           @secGrpBranch = @tree.appendItem(@topmost, "Security Groups", @folder_open, @folder_closed)
           @serverBranch = @tree.appendItem(@topmost, "Servers", @folder_open, @folder_closed)
            if @ec2_main.settings.get('RDS_URL') != nil and @ec2_main.settings.get('RDS_URL') != ""
              @dbBranch = @tree.appendItem(@topmost, "RDS", @folder_open, @folder_closed)
              @dbsecGrpBranch = @tree.appendItem(@topmost, "DB Security Groups", @folder_open, @folder_closed)
              @dbparmBranch = @tree.appendItem(@topmost, "DB Parameter Groups", @folder_open, @folder_closed)
              @dbsnapBranch = @tree.appendItem(@topmost, "DB Snapshots", @folder_open, @folder_closed)
              @dbeventsBranch = @tree.appendItem(@topmost, "DB Events", @folder_open, @folder_closed)
           end
           if platform != "openstack"
              @ebsVolBranch = @tree.appendItem(@topmost, "EBS Volumes", @folder_open, @folder_closed)
              @ebsSnapBranch = @tree.appendItem(@topmost, "EBS Snapshots", @folder_open, @folder_closed)
              @eipSnapBranch = @tree.appendItem(@topmost, "Elastic IPs", @folder_open, @folder_closed)
              @kpBranch = @tree.appendItem(@topmost, "Key Pairs", @folder_open, @folder_closed)
              @imagesBranch = @tree.appendItem(@topmost, "Images", @folder_open, @folder_closed)
           end   
	   if platform != "eucalyptus" and platform != "openstack"
	      @cfBranch = @tree.appendItem(@topmost, "Cloud Formation Templates", @folder_open, @folder_closed)
	      @cfsBranch = @tree.appendItem(@topmost, "Cloud Formation Stacks", @folder_open, @folder_closed)
              @spotBranch = @tree.appendItem(@topmost, "Spot Requests", @folder_open, @folder_closed)
              @elbBranch = @tree.appendItem(@topmost, "Load Balancers", @folder_open, @folder_closed)
	      @launchBranch = @tree.appendItem(@topmost, "Launch Configurations", @folder_open, @folder_closed)
	      @autoscaleBranch = @tree.appendItem(@topmost, "Auto Scaling Groups", @folder_open, @folder_closed)
           end
           @localServersBranch = @tree.appendItem(@topmost, "Local Servers", @folder_open, @folder_closed)
           instances = {}
           @ec2_main.serverCache.refreshServerTree(@tree, @serverBranch,  @parallel, @light,  @nolight, @connect, @disconnect)
           puts "returned from refreshServerTree"
           if @ec2_main.settings.get('RDS_URL') != nil and @ec2_main.settings.get('RDS_URL') != ""
              @ec2_main.serverCache.refreshDBTree(@tree, @dbBranch, @paralleldb, @database, @nolight, @connect, @disconnect)
           end   
           if @ec2_main.environment.connection_failed
              @topmost.text = "Env - Error Connection failed"
           else
              keypair = @ec2_main.settings.get('KEYPAIR_NAME')
              if keypair != nil and keypair.length>0
                 @topmost.text = "Env - #{@env} (Keypair #{keypair})"
              else 
                 @topmost.text = "Env - #{@env}"
              end   
           end
           @status = "loaded"
           @ec2_main.app.forceRefresh
        #end
     end 
  end   
     
  def load_empty
        @tree.clearItems
        @topmost = @tree.appendItem(nil, "Env", @folder_open, @folder_closed)
        @tree.expandTree(@topmost)
        @tree.appendItem(@topmost, "Settings", @doc_settings, @doc_settings)
        @secGrpBranch = @tree.appendItem(@topmost, "Security Groups", @folder_open, @folder_closed)
        @serverBranch = @tree.appendItem(@topmost, "Servers", @folder_open, @folder_closed)
        @ebsVolBranch = @tree.appendItem(@topmost, "EBS Volumes", @folder_open, @folder_closed)
        @ebsSnapBranch = @tree.appendItem(@topmost, "EBS Snapshots", @folder_open, @folder_closed)
        @eipSnapBranch = @tree.appendItem(@topmost, "Elastic IPs", @folder_open, @folder_closed)
        @kpBranch = @tree.appendItem(@topmost, "Key Pairs", @folder_open, @folder_closed)
        @imagesBranch = @tree.appendItem(@topmost, "Images", @folder_open, @folder_closed)
        @cfBranch = @tree.appendItem(@topmost, "Cloud Formation Templates", @folder_open, @folder_closed)
	@cfsBranch = @tree.appendItem(@topmost, "Cloud Formation Stacks", @folder_open, @folder_closed)
        @spotBranch = @tree.appendItem(@topmost, "Spot Requests", @folder_open, @folder_closed)
        @elbBranch = @tree.appendItem(@topmost, "Load Balancers", @folder_open, @folder_closed)
        @localServersBranch = @tree.appendItem(@topmost, "Local Servers", @folder_open, @folder_closed)
        instances = {}
        @status = "empty"
  end    
        

 def refresh
    puts "Tree.refesh"
    @settings = @ec2_main.settings
    platform = @ec2_main.settings.get("EC2_PLATFORM")
    @server = @ec2_main.server
    @secgrp = @ec2_main.secgrp
    if @topmost.class  == Fox::FXTreeItem and  @topmost.text != "Loading......"
      # thread hangs in ruby 192
      #tr=Thread.new do
       @status = "loading"
       @tree.clearItems
       #@settings.load_system
       @env = @settings.get_system("ENVIRONMENT")
       @auto = @settings.get_system("AUTO")
       @settings.load
       @topmost = @tree.appendItem(nil, "Loading......", @online, @online)
       @tree.expandTree(@topmost)
       @tree.appendItem(@topmost, "Settings", @doc_settings, @doc_settings)
       @secGrpBranch = @tree.appendItem(@topmost, "Security Groups", @folder_open, @folder_closed)
       @serverBranch = @tree.appendItem(@topmost, "Servers", @folder_open, @folder_closed)
       if @ec2_main.settings.get('RDS_URL') != nil and @ec2_main.settings.get('RDS_URL') != ""
          @dbBranch = @tree.appendItem(@topmost, "RDS", @folder_open, @folder_closed)
          @dbsecGrpBranch = @tree.appendItem(@topmost, "DB Security Groups", @folder_open, @folder_closed)
          @dbparmBranch = @tree.appendItem(@topmost, "DB Parameter Groups", @folder_open, @folder_closed)
          @dbsnapBranch = @tree.appendItem(@topmost, "DB Snapshots", @folder_open, @folder_closed)
          @dbeventsBranch = @tree.appendItem(@topmost, "DB Events", @folder_open, @folder_closed)
       end   
       instances = {}
       if platform != "openstack"
          @ebsVolBranch = @tree.appendItem(@topmost, "EBS Volumes", @folder_open, @folder_closed)
          @ebsSnapBranch = @tree.appendItem(@topmost, "EBS Snapshots", @folder_open, @folder_closed)
          @eipSnapBranch = @tree.appendItem(@topmost, "Elastic IPs", @folder_open, @folder_closed)
          @kpBranch = @tree.appendItem(@topmost, "Key Pairs", @folder_open, @folder_closed)
          @imagesBranch = @tree.appendItem(@topmost, "Images", @folder_open, @folder_closed)
       end   
       if platform != "eucalyptus" and platform != "openstack"
          @cfBranch = @tree.appendItem(@topmost, "Cloud Formation Templates", @folder_open, @folder_closed)
	  @cfsBranch = @tree.appendItem(@topmost, "Cloud Formation Stacks", @folder_open, @folder_closed)
          @spotBranch = @tree.appendItem(@topmost, "Spot Requests", @folder_open, @folder_closed)
          @elbBranch = @tree.appendItem(@topmost, "Load Balancers", @folder_open, @folder_closed)
          @launchBranch = @tree.appendItem(@topmost, "Launch Configurations", @folder_open, @folder_closed)
          @autoscaleBranch = @tree.appendItem(@topmost, "Auto Scaling Groups", @folder_open, @folder_closed)
       end
       @localServersBranch = @tree.appendItem(@topmost, "Local Servers", @folder_open, @folder_closed)
       @ec2_main.serverCache.refreshServerTree(@tree, @serverBranch, @parallel, @light, @nolight, @connect, @disconnect)
       if @ec2_main.settings.get('RDS_URL') != nil and @ec2_main.settings.get('RDS_URL') != ""
          @ec2_main.serverCache.refreshDBTree(@tree, @dbBranch, @paralleldb, @database, @nolight, @connect, @disconnect)
       end   
       if @ec2_main.environment.connection_failed
         @topmost.text = "Env - Error Connection failed"
      else
         keypair = @ec2_main.settings.get('KEYPAIR_NAME')
         if keypair != nil and keypair.length>0
            @topmost.text = "Env - #{@env} (Keypair #{keypair})"
         else 
            @topmost.text = "Env - #{@env}"
         end
      end
      @status = "loaded"
      @ec2_main.app.forceRefresh
     #end
    end
 end

 def addInstance(secGroup, instanceId)
    r = @tree.prependItem(@serverBranch, "#{secGroup}/#{instanceId}", @connect, @connect)
    @tree.selectItem(r)
 end
 
 def addDBInstance(db_instanceId)
     r = @tree.prependItem(@dbBranch, "DBInstance/" +db_instanceId, @connect, @connect)
     @tree.selectItem(r)
 end
 
 def addSecGrp(groupName)
    @tree.prependItem(@serverBranch, groupName, @parallel, @parallel, groupName)
 end  
 
 def addDBSecGrp(groupName)
     @tree.prependItem(@dbBranch, groupName, @paralleldb, @paralleldb, groupName)
 end  
 
 def delete_secGrp(groupName)
     t = @tree.findItem(groupName)
     if t != nil 
        p = t.parent
        if p != nil
           if p.text() == "Servers"
              @tree.removeItem(t)
           end
        else
           puts "Security Group not found in tree" 
        end            
     else
        puts "Security Group not found in tree" 
     end   
 end 
 
 # this needs to handle case when EC2 and RDS sec grp are the same
 def delete_db_secGrp(groupName)
      t = @tree.findItem(groupName)
      p = t.parent
      if t != nil and p != nil
         if p.text() == "RDS"
            @tree.removeItem(t)
         end   
      else
         puts "Security Group not found in tree" 
      end   
 end 
 
  def status
    @status   
  end

  def error_message(title,message)
         FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end


end
