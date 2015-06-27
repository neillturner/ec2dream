require 'rubygems'
require 'fox16'
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
    @refresh = @ec2_main.makeIcon("arrow_refresh.png")
    @refresh.create
    @topmost_text = ""
    @vpc_serverBranch = {}
    @launchBranch = nil
  end  

  def load(env)
    puts "tree.cache.load #{env}"
    @env = env
    platform = @ec2_main.settings.get("EC2_PLATFORM")
    if @topmost == nil or (@topmost.class  == Fox::FXTreeItem and @topmost.text != "Loading......")
      @status = "loading"
      load_empty
      @tree.collapseTree(@environments)
      @conn = {} 
      @topmost = @tree.appendItem(nil, "Env - #{env}", @online, @online)
      @tree.expandTree(@topmost)
      config = $ec2_main.cloud.config()
      parent = @topmost
      @tree.appendItem(@topmost, "Refresh", @refresh, @refresh)
      config["Cloud"].each do |m|
        if m[0] != "Compute"
          parent = @tree.appendItem(@topmost, m[0], @folder_open, @folder_closed)
        else 
          parent = @topmost
        end   
        config["Cloud"][m[0]].each do |t|
          if t[1]["menu"] == nil or  t[1]["menu"] != false      
            if t[0] == "Servers" or t[0] == "Apps"
              @serverBranch = @tree.appendItem(parent, t[0], @folder_open, @folder_closed)
              if  @ec2_main.settings.amazon 
                @ec2_main.environment.vpc.describe_vpcs.each do |r|
                  @vpc_serverBranch[r['vpcId']] = @tree.appendItem(parent, r['vpcId'], @folder_open, @folder_closed)
                end
              end  
            else
              a = @tree.appendItem(parent, t[0], @folder_open, @folder_closed)
              @launchBranch = a if t[0] == "Launch"
            end    
          end
        end 
      end
      @ec2_main.serverCache.refreshServerTree(@tree, @serverBranch, @parallel, @light, @nolight, @connect, @disconnect) if @serverBranch != nil
      @vpc_serverBranch.each do |vpcid,branch|
        @ec2_main.serverCache.refreshVpcServerTree(@tree, branch, @parallel, @light, @nolight, @connect, @disconnect,vpcid)
      end
      refresh_launch
      if @ec2_main.environment.connection_failed
        @topmost.text = "Env - Error Connection failed"
      else
        @topmost.text = "Env - #{@env}"
      end
      @status = "loaded"
      @ec2_main.app.forceRefresh
    else 
      puts "not loading the tree at environment load time"
    end 
  end  

  def load_empty
    puts "tree.cache.load_empty"
    @tree.clearItems
    @vpc_serverBranch = {}
    @launchBranch = nil
    @environments = @tree.appendItem(nil, "Environments", @doc_settings, @doc_settings) 
    @tree.expandTree(@environments)
    envs = nil
    local_repository = "#{ENV['EC2DREAM_HOME']}/env"
    if !File.directory? local_repository
      puts "creating....#{local_repository}"
      Dir.mkdir(local_repository)
    end 
    begin
      envs = Dir.entries($ec2_main.settings.get_system("REPOSITORY_LOCATION"))
    rescue
      error_message("Repository Location does not exist",$!)
    end
    if envs != nil
      @tree.appendItem(@environments, "Create New Environment", @online, @online)
      @tree.appendItem(@environments, "Delete Existing Environment", @online, @online)
      envs.each do |e|
        if e != "." and e != ".." and e != "system.properties"
          @tree.appendItem(@environments, e, @online, @online)
        end 
      end
    end 
    instances = {}
    @status = "empty"			
  end
  def refresh
    puts "Tree.refesh"	
    if @topmost == nil or (@topmost.class  == Fox::FXTreeItem and  @topmost.text != "Loading......")
      if @ec2_main.settings.amazon or @ec2_main.settings.openstack or @ec2_main.settings.cloudfoundry or @ec2_main.settings.cloudstack or @ec2_main.settings.eucalyptus or @ec2_main.settings.google	
        @serverBranch.each do |a|
          @tree.removeItem(a)
        end 
        @vpc_serverBranch.each do |vpcid,branch|
          branch.each do |a|
            @tree.removeItem(a)
          end   
        end
        @ec2_main.serverCache.refreshServerTree(@tree, @serverBranch, @parallel, @light, @nolight, @connect, @disconnect) if @serverBranch != nil
        @vpc_serverBranch.each do |vpcid,branch|
          @ec2_main.serverCache.refreshVpcServerTree(@tree, branch, @parallel, @light, @nolight, @connect, @disconnect,vpcid)
        end
        refresh_launch      
      else
        refresh_env  
      end		
    end 
  end 

  def refresh_env
    puts "Tree.refresh_env"	
    if @topmost == nil or (@topmost.class  == Fox::FXTreeItem and  @topmost.text != "Loading......")
      command = Thread.new do
      @environments.each do |a|
        @tree.removeItem(a)
      end 	   
      @tree.expandTree(@environments)
      envs = nil
      local_repository = "#{ENV['EC2DREAM_HOME']}/env"
      if !File.directory? local_repository
        puts "creating....#{local_repository}"
        Dir.mkdir(local_repository)
      end 
      begin
        envs = Dir.entries($ec2_main.settings.get_system("REPOSITORY_LOCATION"))
      rescue
        error_message("Repository Location does not exist",$!)
      end
      if envs != nil
        @tree.appendItem(@environments, "Create New Environment", @online, @online)
        @tree.appendItem(@environments, "Delete Existing Environment", @online, @online)
        envs.each do |e|
          if e != "." and e != ".." and e != "system.properties"
            @tree.appendItem(@environments, e, @online, @online)
          end 
        end
      end 
      end      
    end 
  end 

  def refresh_launch
    puts "Tree.refresh_launch"	
    if (@launchBranch != nil) and (@topmost == nil or (@topmost.class  == Fox::FXTreeItem and  @topmost.text != "Loading......"))
      @launchBranch.each do |a|
        @tree.removeItem(a)
      end 	   
      #   @tree.expandTree(@launchBranch)
      profile_folder = "launch"
      envs = nil
      begin
        envs = Dir.entries(@ec2_main.settings.get_system('ENV_PATH')+"/"+profile_folder)
      rescue
        error_message("Launch directory does not exist",$!)
      end
      if envs != nil
        envs.each do |e|
          if e.end_with?(".properties") 
            @tree.appendItem(@launchBranch, e[0..-12], @parallel, @parallel)
          end 
        end
      end 
    end 
  end 

  # DONE 
  def addInstance(secGroup, instanceId,vpc=nil)
    if vpc == nil 
      r = @tree.prependItem(@serverBranch, "#{secGroup}/#{instanceId}", @connect, @connect)
      @tree.selectItem(r)
    else 
      r = @tree.prependItem(@vpc_serverBranch[vpc], "#{secGroup}/#{instanceId}", @connect, @connect)
      @tree.selectItem(r)    
    end
  end
  
  # need to figure out how to find tree items that are the same...
  def delete_secGrp(groupName,vpc=nil)
    start = @serverBranch if vpc == nil or vpc == ""
    start = @vpc_serverBranch[vpc] if vpc != nil and vpc != ""
    t = @tree.findItem(groupName,start)
    if t != nil 
      p = t.parent
      if p != nil
        if (p.text() == "Servers" and (vpc == nil  or vpc == "")) or 
          ((vpc != nil and vpc != "") and p.text() == vpc)
          @tree.removeItem(t)
        end
      else
        puts "Security Group not found in tree" 
      end            
    else
      puts "Security Group not found in tree" 
    end   
  end 
  def status
    @status   
  end

end
