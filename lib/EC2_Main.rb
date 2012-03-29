#!/usr/bin/ruby

#$LOAD_PATH << "." 

#puts $LOAD_PATH

require 'rubygems'
require 'fox16'
require 'fox16/colors' 
require 'net/http'
require 'resolv'
require 'EC2_Settings'
require 'EC2_Server'
require 'EC2_SecGrp'
require 'EC2_Launch'
require 'EC2_Environment'
require 'EC2_List'
require 'dialog/EC2_SystemDialog'
require 'EC2_Notes'
require 'cache/EC2_TreeCache'
require 'cache/EC2_ServerCache'
require 'cache/EC2_ImageCache'

include Fox

class EC2_Main < FXMainWindow
 
 
  def makeIcon(filename)
    begin
      filename = File.join("#{ENV['EC2DREAM_HOME']}/lib/icons", filename)
      icon = nil
      File.open(filename, "rb") do |f|
        icon = FXPNGIcon.new(getApp(), f.read)
      end
      icon
    rescue
      raise RuntimeError, "Couldn't load icon: #{filename}"
    end
  end  


  def initialize(app)
    puts "main.initialize "+RUBY_PLATFORM
    $ec2_main = self
    @initial_startup = false
    @app = app
    # Do base class initialize first
    super(app, "EC2Dream v3.2.0 - Build and Manage Cloud Servers", :opts => DECOR_ALL, :width => 900, :height => 650)

    # Status bar
    status = FXStatusBar.new(self,
      LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|STATUSBAR_WITH_DRAGCORNER)

    # Main window interior
    @splitter = FXSplitter.new(self, (LAYOUT_SIDE_TOP|LAYOUT_FILL_X|
      LAYOUT_FILL_Y|SPLITTER_TRACKING))  
        
    group1 = FXVerticalFrame.new(@splitter,
      LAYOUT_FILL_X|LAYOUT_FILL_Y,:width => 250)
    group2 = FXVerticalFrame.new(@splitter,
      LAYOUT_FILL_X|LAYOUT_FILL_Y)     
        
    #left hand tree panel   
    @tree = FXTreeList.new(group1,
    	      :opts => (LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_RIGHT|TREELIST_SHOWS_LINES|
      TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|TREELIST_SINGLESELECT))
      
    @treeCache = EC2_TreeCache.new(self,@tree) 
    @serverCache = EC2_ServerCache.new(self,@tree)
    @imageCache = EC2_ImageCache.new(self)
       
    # Environment Panel 
    @tabBook = FXTabBook.new(group2, nil, 0,
      LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
    @environment = EC2_Environment.new(self,app)
    
    # Server panel  
     @server = EC2_Server.new(self)
      
    # Launch panel  
     @launch = EC2_Launch.new(self) 
     
    # SecGrp panel  
     @secgrp = EC2_SecGrp.new(self) 
        
    # list panel 	
     @list = EC2_List.new(self,app)
     
        
    # Settings panel
     @settings = EC2_Settings.new(self)
    # load system parameters 
     @settings.load_system
     
    # Notes
     @notes = EC2_Notes.new(self)
     
     # need to cope with case of no system.properties file and the value not set. 
     @environment.initial_load 
    
     @tree.connect(SEL_SELECTED) do |sender, sel, item|
         tree_process(item)
     end 
     
  end

  def tree_process(item)
    puts "main.tree_process"
    keypair = settings.get('KEYPAIR_NAME')
    conn_failed = @environment.connection_failed
    if !conn_failed 
     case item.text
        when "Env - #{@environment.env}","Env - #{@environment.env} (Keypair #{keypair})"
           puts "environment"
           #@tabBook.setCurrent(0)
           treeCache.refresh()
        when "Settings"
           puts "editSettings"
           @tabBook.setCurrent(5)
        when "Security Groups"
           puts "editSecGrps"
           @secgrp.clear
           @secgrp.setType_ec2
           @tabBook.setCurrent(3)
        when "DB Security Groups"
           puts "edit DBSecGrps"
           @secgrp.clear
           @secgrp.setType_rds
           @tabBook.setCurrent(3)   
        when "Servers","EBS Volumes","EBS Snapshots","Elastic IPs","Key Pairs","Images","DB Parameter Groups","DB Snapshots","DB Events","Spot Requests","Load Balancers","Launch Configurations","Auto Scaling Groups","Local Servers","Cloud Formation Templates","Cloud Formation Stacks"
           if @settings.get("EC2_PLATFORM") != "openstack" or item.text == "Local Servers"
  	      puts item.text
	      @tabBook.setCurrent(4)
	      @list.load(item.text)
	   end   
        else
           if item.parent != nil
              case (item.parent).text
                 when "Servers"
                    s_id = "/i-"  
                    if @settings.get("EC2_PLATFORM") == "openstack"
                       s_id="/"
                    end  
                    if item.text[s_id] != nil
                      sa = (item.text).split(s_id)
		      if sa.size>1
		        @launch.load(sa[0])
		        @secgrp.load(sa[0])
		        #@scripts.load(sa[0])
		        #@stacks.remote_host(sa[0])
      		      end
      		      @server.load_server(item.text)
                      @tabBook.setCurrent(1)
      		     else
      		      @server.clear_panel
      		      @launch.load(item.text)
      		      @secgrp.load(item.text)
      		      @tabBook.setCurrent(2)
                     end
         	 when "RDS"
                     if item.text["/"] != nil
                      sa = (item.text).split"/"
 		      if sa.size>1
		        @launch.clear_panel
		        @secgrp.clear()
      		      end
      		      @server.load_rds_server(item.text)
                      @tabBook.setCurrent(1)
      		     else
      		      @server.clear_rds_panel
      		      @launch.load_rds(item.text)
      		      @secgrp.load_rds(item.text)
      		      @tabBook.setCurrent(2)
                     end
         	 when "Images"
         	      if item.text["("] != nil 
         	         sa = (item.text).split"("
		         if sa.size>1
		           im = sa[1]
		           puts im[0,im.length-1]
         	           @launch.load_profile(im[0,im.length-1])
         	           @tabBook.setCurrent(2)
         	         end  
         	      end  
                 end
        end 
     end
    end
  end             
  
  def browser(url)
     @environment.browser(url)
  end  
    
  def tabBook
     return @tabBook
  end
  
  def server
   return @server
  end
  
  def launch
     return @launch
  end
  
  def secgrp
     return @secgrp
  end
  
  def list
       return @list
  end
  
    
  def settings
   return @settings
  end
  
  def notes
     return @notes
  end
  
  def environment 
   return @environment
  end
  
  def treeCache
     @treeCache
  end 
  
  def serverCache
     @serverCache
  end 
  
  def imageCache
     @imageCache
  end 
  
  def tree 
     return @tree
  end
  
  def app
    return @app
  end  

  def onCmdTracking(sender, sel, ptr)
    @splitter.splitterStyle ^= SPLITTER_TRACKING
    return 1
  end

  def onUpdTracking(sender, sel, ptr)
    if (@splitter.splitterStyle & SPLITTER_TRACKING) != 0
      sender.handle(self, FXSEL(SEL_COMMAND, ID_CHECK), nil)
    else
      sender.handle(self, FXSEL(SEL_COMMAND, ID_UNCHECK), nil)
    end
    return 1
  end
  
  def error_message(title,message)
      FXMessageBox.warning(self,MBOX_OK,title,message)
   end
  
  def enable_if_env_set(sender)
      @env = @environment.env
      if @env != nil and @env.length>0
      	sender.enabled = true
      else
        sender.enabled = false
      end
  end 
  
  def enable_if_server_loaded(sender)
     if @server.loaded
         sender.enabled = true
     else
         sender.enabled = false
     end 
  end
  
  def create
    super
    show(PLACEMENT_SCREEN)
     if !File.exists?(ENV['EC2DREAM_HOME']+"/env/system.properties")
       systemdialog = EC2_SystemDialog.new(self)
       systemdialog.execute(PLACEMENT_DEFAULT)
    end   
  end
  
 
end  


