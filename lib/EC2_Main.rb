#!/usr/bin/ruby

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
require 'dialog/EC2_EnvCreateDialog'
require 'dialog/EC2_EnvDeleteDialog'
require 'cache/EC2_TreeCache'
require 'cache/EC2_ServerCache'
require 'cache/EC2_ImageCache'
require 'Amazon'
require 'Google_compute'
require 'Hp'
require 'Rackspace'
require 'OpenStack'
require 'Eucalyptus'
require 'CloudStack'
require 'Cloud_Foundry'
require 'Servers'

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


  def initialize(app,product)
    puts "main.initialize "+RUBY_PLATFORM
    $ec2_main = self
    @initial_startup = false
    @app = app
    super(app, "#{product} v3.7.4 - Build and Manage Cloud Servers", :opts => DECOR_ALL, :width => 900, :height => 650)

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

        # list panel
     @list = EC2_List.new(self,app)

    # Server panel
     @server = EC2_Server.new(self)

    # Launch panel
     @launch = EC2_Launch.new(self)

    # SecGrp panel
     @secgrp = EC2_SecGrp.new(self)

    # Settings panel
     @settings = EC2_Settings.new(self)
    # load system parameters
     @settings.load_system


     # need to cope with case of no system.properties file and the value not set.
     @environment.initial_load
     @tree.connect(SEL_SELECTED) do |sender, sel, item|
         tree_process(item)
     end
  end

  def tree_process(item)
    puts "main.tree_process"
    conn_failed = @environment.connection_failed
    if !conn_failed
     if item.parent == nil
       tree_top_level(item)
     elsif (item.parent).parent == nil and (item.parent).text == "Environments"
       if item.text == "Create New Environment"
              dialog = EC2_EnvCreateDialog.new($ec2_main)
              dialog.execute
               puts "Environment Created #{dialog.created}"
              if dialog.created
                 @environment.reset_connection
                 @environment.load_env
              end
       elsif item.text == "Delete Existing Environment"
              if @treeCache.status != "loading"
                 dialog = EC2_EnvDeleteDialog.new($ec2_main)
             dialog.execute
                         if dialog.success
                            @treeCache.refresh_env
                         end
          end
       else
          @settings.put_system('ENVIRONMENT',item.text)
          @settings.save_system
          @environment.reset_connection
                  @imageCache.set_status("empty")
          @environment.load_env
       end
     elsif (item.parent).parent == nil  and ((item.parent).text == "Env - #{@environment.env}")
       tree_first_level(item)
     elsif (item.parent).parent != nil
       tree_second_level(item)
     end
    end
  end

  def tree_top_level(item)
     if item.text == "Environments"
        puts "environment"
        @tabBook.setCurrent(4)
     elsif item.text == "Env - #{@environment.env}"
        puts "environment"
        @tabBook.setCurrent(4)
     end
  end

  def tree_first_level(item)
     if (item.parent).parent != nil
       tree_second_level(item)
     else
        case item.text
          when "Refresh"
              puts "refresh environment"
              treeCache.refresh()
          when "Launch"
             puts "launch"
             @launch.clear_panel
             @tabBook.setCurrent(2)
          when "Servers","Apps"
             puts "#{item.text}"
             @tabBook.setCurrent(0)
             @list.load(item.text)
           else
             if (item.text).start_with? "vpc-"
                    puts "#{item.text}"
                @tabBook.setCurrent(0)
                @list.load("Servers")
                 else
              puts "first level menu #{item.text}"
                  if item.numChildren == 0
           puts item.text
               @tabBook.setCurrent(0)
               @list.load(item.text)
             else
                    if item.expanded?
                          @tree.collapseTree(item)
                        else
                          @tree.expandTree(item)
            end
          end
                 end
        end
      end
   end

   def tree_second_level(item)
      # need to handle a server not under a security group
         if ((item.parent).parent).text == "Servers" or (item.parent).text == "Servers"
                    process_server(item)
                 elsif (((item.parent).parent).text).start_with? "vpc-"
            process_server(item,((item.parent).parent).text)
                 elsif ((item.parent).text).start_with? "vpc-"
            process_server(item,(item.parent).text)
         else
                        case (item.parent).text
                          when "Apps"
                               sa = (item.text).split"/"
                               g = ""
                               if sa.size>1
                                  g = sa[0]
                                 if g != nil and g != ""
                                    @launch.load(g)
                                    @server.load(item.text)
                                     @tabBook.setCurrent(1)
                                  end
                               else
                                 @launch.load(item.text)
                                 @server.clear_panel
                                  @tabBook.setCurrent(2)
                               end
                                          when "Launch"
                                                  puts "Launch #{item.text} "
                                                  @launch.load(item.text)
                                                  @tabBook.setCurrent(2)
                          else
                              puts "second level menu #{item.text} #{(item.parent).text}"
                              @tabBook.setCurrent(0)
                              @list.load(item.text,(item.parent).text)
                          end
            end
   end

  def process_server(item,vpc=nil)
                 s_id = "/i-"
                 if settings.openstack or settings.google
                   s_id="/"
                 end
                 if item.text[s_id] != nil
                    sa = (item.text).split(s_id)
                    g = ""
                    n = ""
                    if sa.size>1
                       g = serverCache.instance_sec_group(sa[1])
                       n=sa[0]
                       if g == nil or g == ""
                          g = sa[0]
                       end
                    end
                    if g != nil and g != ""
                       @launch.load(n)
                       @secgrp.load(g,vpc)
                    end
                    @server.load_server(item.text)
                    @tabBook.setCurrent(1)
                 else
                    @server.clear_panel
                    @launch.clear_panel
                    # comment out for openstack code problem
                    @secgrp.load(item.text,vpc)
                    @tabBook.setCurrent(3)
                 end
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

  def secGrp
     return @secgrp
  end

  def list
       return @list
  end


  def settings
   return @settings
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

  def cloud
      platform = @settings.get("EC2_PLATFORM")
          case platform
           when "amazon"
             if @Amazon != nil
           @Amazon
         else
           @Amazon = Amazon.new
                 end
            when "google"
             if @Google != nil
           @Google
         else
           @Google = Google_compute.new
                 end
       when "openstack_hp"
             if @Hp != nil
           @Hp
         else
           @Hp = Hp.new
                 end
       when "openstack_rackspace"
             if @Rackspace != nil
           @Rackspace
         else
           @Rackspace = Rackspace.new
                 end
       when "openstack"
             if @OpenStack != nil
           @OpenStack
         else
           @OpenStack = OpenStack.new
                 end
       when "eucalyptus"
             if @Eucalyptus != nil
           @Eucalyptus
         else
           @Eucalyptus = Eucalyptus.new
                 end
           when "cloudstack"
             if @CloudStack != nil
           @CloudStack
         else
           @CloudStack = CloudStack.new
                 end
           when "cloudfoundry"
             if @Cloud_Foundry != nil
           @Cloud_Foundry
         else
           @Cloud_Foundry = Cloud_Foundry.new
                 end
           when "servers"
             if @Servers != nil
           @Servers
         else
           @Servers = Servers.new
                 end
      end
  end

  def cloud_reset
    @Amazon = nil
        @Google = nil
    @Hp = nil
    @Rackspace = nil
    @OpenStack = nil
    @Eucalyptus = nil
    @CloudStack = nil
    @Cloud_Foundry = nil
        @Servers = nil
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
       dialog = EC2_SystemDialog.new(self)
       dialog.execute(PLACEMENT_DEFAULT)
       treeCache.load_empty
    end
  end


end


