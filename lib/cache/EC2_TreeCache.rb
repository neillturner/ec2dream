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
	
end  

  def load(env)
     @env = env
     platform = @ec2_main.settings.get("EC2_PLATFORM")
     if @topmost == nil or (@topmost.class  == Fox::FXTreeItem and @topmost.text != "Loading......")
	  #tr=Thread.new do
	  @status = "loading"
          #@tree.clearItems
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
                     else
                        a = @tree.appendItem(parent, t[0], @folder_open, @folder_closed)
                     end    
                  end
               end 
          end
          @ec2_main.serverCache.refreshServerTree(@tree, @serverBranch, @parallel, @light, @nolight, @connect, @disconnect) if @serverBranch != nil
            if @ec2_main.environment.connection_failed
               @topmost.text = "Env - Error Connection failed"
            else
               @topmost.text = "Env - #{@env}"
            end
         @status = "loaded"
         @ec2_main.app.forceRefresh
     end 
  end  

  def load_empty
             @tree.clearItems
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
       if @ec2_main.settings.amazon or @ec2_main.settings.openstack or @ec2_main.settings.cloudfoundry or @ec2_main.settings.cloudstack or @ec2_main.settings.eucalyptus 	
	      @serverBranch.each do |a|
             @tree.removeItem(a)
          end 	   
	      @ec2_main.serverCache.refreshServerTree(@tree, @serverBranch, @parallel, @light, @nolight, @connect, @disconnect) if @serverBranch != nil
		else
          refresh_env  
        end		
    end 
end 

def refresh_env
   puts "Tree.refesh_env"	
   if @topmost == nil or (@topmost.class  == Fox::FXTreeItem and  @topmost.text != "Loading......")	
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
 	
 def addInstance(secGroup, instanceId)
    r = @tree.prependItem(@serverBranch, "#{secGroup}/#{instanceId}", @connect, @connect)
    @tree.selectItem(r)
 end
 
 def addSecGrp(groupName)
    @tree.prependItem(@serverBranch, groupName, @parallel, @parallel, groupName)
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
 
 def status
    @status   
  end

end
