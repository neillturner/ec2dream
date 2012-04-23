
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'fog'
require 'EC2_Settings'
require 'dialog/EC2_EnvDialog'
require 'dialog/EC2_EnvCreateDialog'
require 'dialog/EC2_EnvCopyDialog'
require 'dialog/EC2_EnvDeleteDialog'
require 'dialog/EC2_SystemDialog'
require 'dialog/EC2_SecGrpDialog'
require 'cache/EC2_TreeCache'

class EC2_Environment < FXImageFrame
    
  def initialize(owner, app)
        @ec2_main = owner
        @ec2 = nil
        @ec2_thread = nil
        @mon = nil
        @s3 = nil
        @as = nil
        @rds = nil
        @ec2_failed = false
        @elb = nil
        @env = nil
        tab1 = FXTabItem.new(@ec2_main.tabBook, " Environment ")
        page1 = FXVerticalFrame.new(@ec2_main.tabBook, LAYOUT_FILL, :padding => 0)
        page1a = FXHorizontalFrame.new(page1,LAYOUT_FILL_X, :padding => 0)
	@server_label = FXLabel.new(page1a, "" )
	@refresh_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@arrow_refresh = @ec2_main.makeIcon("arrow_refresh.png")
	@arrow_refresh.create
	@refresh_button.icon = @arrow_refresh
	@refresh_button.tipText = "Refresh Environment"
	@refresh_button.connect(SEL_COMMAND) do |sender, sel, data|
	    puts "server.refresh.connect"
	    @ec2_main.treeCache.refresh
	end
	@refresh_button.connect(SEL_UPDATE) do |sender, sel, data|
	    enable_if_env_set(sender)
	end
	@online    = @ec2_main.makeIcon("status_online.png")
	@online.create
	@selenv_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@selenv_button.icon = @online
	@selenv_button.tipText = " Select Environment "
	@selenv_button.connect(SEL_COMMAND) do |sender, sel, data|
	   puts "Environment.selenv.connect"
	   if @ec2_main.treeCache.status != "loading"
	     dialog = EC2_EnvDialog.new(@ec2_main)
	     dialog.execute
	     curr_env = dialog.selected
	     if curr_env == "Create New Environment"
	          createdialog = EC2_EnvCreateDialog.new(@ec2_main)
	          createdialog.execute
		  created = createdialog.created
	   	  if created
                    load
                  end  	          
  	     else
	          if  curr_env != nil and curr_env != ""
	            reset_connection
	            load_env
	          end  
             end
           end  
	end
        @selenv_button.connect(SEL_UPDATE) do |sender, sel, data|
	      disable_if_env_loading(sender) 
	end
	@parallel= @ec2_main.makeIcon("rocket_new.png")
        @parallel.create	
	@secgrp_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@secgrp_button.icon = @parallel
	@secgrp_button.tipText = " Create Security Group "
	@secgrp_button.connect(SEL_COMMAND) do |sender, sel, data|
	  if @ec2_main.treeCache.status != "loading" 
	    @secgrpdialog = EC2_SecGrpDialog.new(@ec2_main)
	    @secgrpdialog.execute
	    created = @secgrpdialog.created
	    sg = @secgrpdialog.sec_grp
	    sg_type = @secgrpdialog.type
	    if created and sg_type == "database"
	       @ec2_main.serverCache.db_secGrps(sg)
	    else
	       if created
	          @ec2_main.serverCache.secGrps(sg)
	       end   
	    end
	  end  
	end
	@secgrp_button.connect(SEL_UPDATE) do |sender, sel, data|
	    disable_if_env_loading(sender)
	    enable_if_env_set(sender) 
	end	
	FXLabel.new(page1a, "                                    ")
	
	@create = @ec2_main.makeIcon("status_online_new.png")
	@create.create
        @create_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)	
	@create_button.icon = @create
	@create_button.tipText = "  Create Environment "
	@create_button.connect(SEL_COMMAND) do |sender, sel, data|
	  if @ec2_main.treeCache.status != "loading"
           createdialog = EC2_EnvCreateDialog.new(@ec2_main)
	   createdialog.execute
	   created = createdialog.created
	   if created
              load
           end
          end 
        end
        @create_button.connect(SEL_UPDATE) do |sender, sel, data|
	      disable_if_env_loading(sender) 
	end	
	@copy = @ec2_main.makeIcon("status_online_copy.png")
	@copy.create
	@copy_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@copy_button.icon = @copy
	@copy_button.tipText = "  Copy Environment "
	@copy_button.connect(SEL_COMMAND) do |sender, sel, data|
	  if @ec2_main.treeCache.status != "loading"
           copydialog = EC2_EnvCopyDialog.new(@ec2_main)
    	   copydialog.execute
	   copied = copydialog.copied
	   if copied
              load
           end
          end 
        end
        @copy_button.connect(SEL_UPDATE) do |sender, sel, data|
	      disable_if_env_loading(sender) 
	end        
	@delete = @ec2_main.makeIcon("status_online_delete.png")
	@delete.create	        
	@delete_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@delete_button.icon = @delete
	@delete_button.tipText = " Delete Environment "
	@delete_button.connect(SEL_COMMAND) do |sender, sel, data|
	  if @ec2_main.treeCache.status != "loading" 
	   deletedialog = EC2_EnvDeleteDialog.new(@ec2_main)
    	   deletedialog.execute
    	   curr_env = @settings.get_system("ENVIRONMENT")
	   if curr_env == nil or  curr_env.length==0 
      	      load_empty_env
    	   end
    	  end 
	end
        @delete_button.connect(SEL_UPDATE) do |sender, sel, data|
	      disable_if_env_loading(sender) 
	end	
        @repository = @ec2_main.makeIcon("drawer.png")
	@repository.create	        
	@repository_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@repository_button.icon = @repository
	@repository_button.tipText = " Environment Repository "
	@repository_button.connect(SEL_COMMAND) do |sender, sel, data|
	   if @ec2_main.treeCache.status != "loading"
              systemdialog = EC2_SystemDialog.new(@ec2_main)
              systemdialog.execute(PLACEMENT_DEFAULT)
              valid_loc = systemdialog.selected
              if valid_loc 
                 initial_load
                 @ec2_main.settings.clear_panel
              end   
           end   
        end
        @repository_button.connect(SEL_UPDATE) do |sender, sel, data|
	      disable_if_env_loading(sender) 
	end        
	@cloud_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@world = @ec2_main.makeIcon("weather_clouds.png")
	@world.create
	@cloud_button.icon = @world
	@cloud_button.tipText = " Cloud Admin "
	@cloud_button.connect(SEL_COMMAND) do |sender, sel, data|
	    url = @ec2_main.settings.get('CLOUD_ADMIN_URL')
	    if url != nil and url != ""
	       browser(url)
	    else
	       error_message(@ec2_main,"Error","No CLOUD_ADMIN_URL in Settings")
	    end   
	end
	@cloud_button.connect(SEL_UPDATE) do |sender, sel, data|
	    enable_if_env_set(sender)
	end	
	        
        
        @help = @ec2_main.makeIcon("help.png")
	@help.create
	@help_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_RIGHT)
	@help_button.icon = @help
	@help_button.tipText = " Help "
	@help_button.connect(SEL_COMMAND) do |sender, sel, data|
	    browser("http://ec2dream.github.com")
	end
        @help_button.connect(SEL_UPDATE) do |sender, sel, data|
	     disable_if_env_loading(sender)
	end	
	page1b = FXHorizontalFrame.new(page1,LAYOUT_FILL_X, :padding => 0)
	@env_title_name = FXLabel.new(page1b, "", nil,:opts => LAYOUT_RIGHT)
	@env_title_name.font = FXFont.new(app, "Arial", 14, :slant => FXFont::Italic)
	@env_repository_loc = FXLabel.new(page1b, "", nil,:opts => LAYOUT_RIGHT)
	@env_repository_loc.font = FXFont.new(app, "Arial", 14, :slant => FXFont::Italic)
	frame1 = FXVerticalFrame.new(page1, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
	frame1a = FXMatrix.new(frame1, 2, MATRIX_BY_COLUMNS|LAYOUT_FILL)
	@env_title1 = FXLabel.new(frame1a, "", nil, LAYOUT_LEFT)
	@env_title1.font = FXFont.new(app, "Arial", 11)
	@env_image1 = FXButton.new(frame1a, "", :opts => BUTTON_TOOLBAR|LAYOUT_LEFT)
	@env_image1.icon = @online
	@env_image1.tipText = " Select Environment "
	@env_image1.connect(SEL_COMMAND) do
	     @dialog = EC2_EnvDialog.new(@ec2_main)
	     @dialog.execute
	     curr_env = @dialog.selected
	     if curr_env == "Create New Environment"
	          @createdialog = EC2_EnvCreateDialog.new(@ec2_main)
	          @createdialog.execute
	          load
	     else
	          if  curr_env != nil and curr_env != ""
	            reset_connection
	            load_env
	          end  
             end
	end
	@env_image1.connect(SEL_UPDATE) do |sender, sel, data|
	   disable_if_env_loading(sender)
	end	
        @env_title2 = FXLabel.new(frame1a, "Before Creating a Server, Create a Security Group by Clicking on the Icon ", nil, LAYOUT_LEFT)
	@env_title2.font = FXFont.new(app, "Arial", 11)
	@env_image2 = FXButton.new(frame1a, "", :opts => BUTTON_TOOLBAR|LAYOUT_LEFT)
	@env_image2.icon = @parallel
	@env_image2.tipText = "Create Security Group"
	@env_image2.connect(SEL_COMMAND) do
	  if @ec2_main.treeCache.status != "loading" 
	    @secgrpdialog = EC2_SecGrpDialog.new(@ec2_main)
	    @secgrpdialog.execute
	    created = @secgrpdialog.created
	    sg = @secgrpdialog.sec_grp
	    if created
	       @ec2_main.serverCache.secGrps(sg)
	    end
	  end  
	end
	@env_image2.connect(SEL_UPDATE) do |sender, sel, data|
	    enable_if_env_set(sender) 
	end

        @env_title4 = FXLabel.new(frame1a, "Before Creating an RDS DBInstance, Create a DBSecurity Group ", nil, LAYOUT_LEFT)
	@env_title4.font = FXFont.new(app, "Arial", 11)
	@env_image4 = FXButton.new(frame1a, "", :opts => BUTTON_TOOLBAR|LAYOUT_LEFT)
	@env_image4.icon = @parallel
	@env_image4.tipText = "Create Security Group"
	@env_image4.connect(SEL_COMMAND) do
	  if @ec2_main.treeCache.status != "loading" 
	    @secgrpdialog = EC2_SecGrpDialog.new(@ec2_main)
	    @secgrpdialog.execute
	    created = @secgrpdialog.created
	    sg = @secgrpdialog.sec_grp
	    if created
	       @ec2_main.serverCache.secGrps(sg)
	    end
	  end  
	end	
	@env_image4.connect(SEL_UPDATE) do |sender, sel, data|
	    enable_if_env_set(sender) 
	end
	
	@env_image = FXJPGImage.new(app, File.open(ENV['EC2DREAM_HOME']+"/lib/sunbeams.jpg" , "rb" ).read)
	FXImageFrame.new(frame1, @env_image,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
  end 
  
  def load
  	puts "environment.load"
  	@settings = @ec2_main.settings
        @env = @settings.get_system("ENVIRONMENT")
      	if @env != nil and @env.length>0 
      	   load_env
      	else
      	   load_empty_env
    	end   
  end 
  
  def initial_load
       puts "environment.initial_load"
       @settings = @ec2_main.settings
       @env = @settings.get_system("ENVIRONMENT")
       @auto = @settings.get_system("AUTO")
       if @env != nil and @env.length>0
          puts "Initial Environment "+@env
       end    
       if @env != nil and @env.length>0    
          puts "Auto Loaded? "+@auto
       end
       if @env != nil and @env.length>0 and @auto == "true"
          @treeCache = @ec2_main.treeCache
          @treeCache.load_empty
          load_env
       else
          load_empty_env
       end
  end     
    
  def load_env
           puts "environment.load_env"
           reset_connection
           @env_title1.text= "To Switch or Create a New Environment - Click on the Icon "
           @settings = @ec2_main.settings
           @server = @ec2_main.server
           @server.clear_panel
           @launch = @ec2_main.launch
           @launch.clear_panel
           @secgrp = @ec2_main.secgrp
           @secgrp.clear
	   @env = @settings.get_system("ENVIRONMENT")
           @auto = @settings.get_system("AUTO")
           @settings.load
           @ec2_main.notes.load 
           @env_title_name.text = "Env - "+@env+"   "
           show_repository_loc
           @treeCache = @ec2_main.treeCache
           @treeCache.load(@env)
           @ec2_main.app.forceRefresh
  end     
     
  def load_empty_env
        puts "environment.load_empty_env"
        @env_title_name.text = ""
        reset_connection
        @env_title1.text= "*** TO START *** Select or Create an Environment by Clicking on the Icon "

        @settings = @ec2_main.settings
        #@settings.load_system
        @env = ""
        @settings.put_system('ENVIRONMENT', "")
        @auto = false
        @settings.put_system('AUTO', "false")
        if File.exists?(ENV['EC2DREAM_HOME']+"/system/system.properties")
           @settings.save_system
        end
        show_repository_loc

        @server = @ec2_main.server
	@server.clear_panel
	@launch = @ec2_main.launch
	@launch.clear_panel
	@secgrp = @ec2_main.secgrp
	@secgrp.clear
        @ec2_main.notes.clear
        @treeCache = @ec2_main.treeCache
        @treeCache.load_empty
        @ec2_main.app.forceRefresh
  end
 
  def env
      return @env 
  end
  
  def connection
   puts "environment.connection"
   if @ec2 != nil
     return @ec2
   else
    settings = @ec2_main.settings
    if settings.get("EC2_PLATFORM") == "openstack"
       begin
          @ec2 = Fog::Compute.new({:provider => 'OpenStack',
            :openstack_auth_url => settings.get('EC2_URL'), 
            :openstack_api_key => settings.get('AMAZON_SECRET_ACCESS_KEY'),  
            :openstack_username => settings.get('AMAZON_ACCESS_KEY_ID')})            
       rescue
         set_connection_failed
         puts "***Error on connection to OpenStack - check your keys in environment.connection"
         puts "conn failed #{@ec2_failed}"
       end      
    elsif settings.get("EC2_PLATFORM") == "eucalyptus"
       begin
         if settings.get('EC2_URL') != nil and settings.get('EC2_URL').length>0
            puts "EC2_URL set to #{ENV['EC2_URL']}"
            @ec2 = RightAws::Ec2.new(settings.get('AMAZON_ACCESS_KEY_ID'),settings.get('AMAZON_SECRET_ACCESS_KEY'), {:endpoint_url => settings.get('EC2_URL'), :multi_thread => true, :eucalyptus => true})
         else 
            @ec2 = RightAws::Ec2.new(settings.get('AMAZON_ACCESS_KEY_ID'), settings.get('AMAZON_SECRET_ACCESS_KEY'), {:multi_thread => true, :eucalyptus => true})
         end
       rescue
          set_connection_failed
          puts "***Error on connection to EC2 - check your keys in environment.connection"
          puts "conn failed #{@ec2_failed}"
       end
    else
       if settings.get("EC2_PLATFORM") == "cloudstack" 
          if  ENV['EC2_API_VERSION'] != "2010-11-15"
             set_connection_failed
             puts "***Error on connection to EC2 - Environment Variable EC2_API_VERSION not set"
             if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil 
               puts "** enter set EC2_API_VERSION=2010-11-15  before running ec2dream **"
             else
               puts "** enter export EC2_API_VERSION=2010-11-15  before running ec2dream  **"
             end 
             puts "conn failed #{@ec2_failed}"          
             return @ec2
          end   
       end
       begin
         if settings.get('EC2_URL') != nil and settings.get('EC2_URL').length>0
            puts "EC2_URL set to #{ENV['EC2_URL']}"
            @ec2 = RightAws::Ec2.new(settings.get('AMAZON_ACCESS_KEY_ID'),settings.get('AMAZON_SECRET_ACCESS_KEY'), :endpoint_url => settings.get('EC2_URL'), :multi_thread => true)
         else 
            @ec2 = RightAws::Ec2.new(settings.get('AMAZON_ACCESS_KEY_ID'), settings.get('AMAZON_SECRET_ACCESS_KEY'), :multi_thread => true)
         end
       rescue
         set_connection_failed
         puts "***Error on connection to EC2 - check your keys in environment.connection"
         puts "conn failed #{@ec2_failed}"
       end
    end   
    return @ec2  
   end
  end
  
  def connection_failed
     return @ec2_failed
  end   
  
  def set_connection_failed
     @ec2 = nil
     @ec2_failed = true
  end   
  
  def reset_connection
    @ec2 = nil
    @ec2_failed = false
  end 
  
  def s3_connection
     puts "environment.s3_connection"
     if @s3 != nil
       return @s3
     else
      settings = @ec2_main.settings
      begin 
         @s3 = RightAws::S3.new(settings.get('AMAZON_ACCESS_KEY_ID'), settings.get('AMAZON_SECRET_ACCESS_KEY'))
         #@s3 = RightAws::S3Interface.new(settings.get('AMAZON_ACCESS_KEY_ID'), settings.get('AMAZON_SECRET_ACCESS_KEY'))
      rescue
        @s3 = nil 
        puts "***Error on connection to S3 - check your keys"
      end
      return @s3  
     end
  end
    
  def reset_s3_connection
      @s3 = nil 
  end
  
 def as_connection
           puts "environment.as_connection"
           if @as != nil
             return @as
           else
             settings = @ec2_main.settings
             if settings.get('EC2_PLATFORM') != nil and settings.get('EC2_PLATFORM').downcase == "amazon" 
               begin
                 if settings.get('EC2_URL') != nil and settings.get('EC2_URL').length>0
                   as_url = settings.get('EC2_URL')
                   as_url = as_url.gsub("ec2.","")
                   as_url = as_url.gsub("https://","https://autoscaling.")
                   puts "Connecting to #{as_url}"  
                   @as = RightAws::AsInterface.new(settings.get('AMAZON_ACCESS_KEY_ID'), settings.get('AMAZON_SECRET_ACCESS_KEY'),  :endpoint_url => as_url, :multi_thread => true)             
                 else
                   @as = RightAws::AsInterface.new(settings.get('AMAZON_ACCESS_KEY_ID'), settings.get('AMAZON_SECRET_ACCESS_KEY'), :multi_thread => true)
                 end   
               rescue
                 @as = nil 
                 puts "***Error on connection to ELB - check your keys"
                 error_message(@ec2_main.tabBook,"Auto Scaling Connection Error",$!.to_s+" - check your EC2 Access Settings")
               end
               return @as  
             else
               @as = nil 
               puts "***No Auto Scaling unless Amazon platform"
             end 
          end
  end
  
    def reset_as_connection
       @as = nil 
    end

  
  def rds_connection
    puts "environment.rds_connection"
    if @rds != nil
      return @rds
    else
      settings = @ec2_main.settings
      begin 
         if settings.get('RDS_URL') != nil and settings.get('RDS_URL').length>0
             @rds = RightAws::RdsInterface.new(settings.get('AMAZON_ACCESS_KEY_ID'),settings.get('AMAZON_SECRET_ACCESS_KEY'), :endpoint_url => settings.get('RDS_URL'), :multi_thread => false)
         else 
            @rds = RightAws::RdsInterface.new(settings.get('AMAZON_ACCESS_KEY_ID'), settings.get('AMAZON_SECRET_ACCESS_KEY'), :multi_thread => false)
         end
      rescue
        @rds = nil 
        puts "***Error on connection to RDS - check your keys"
      end
      return @rds  
    end
  end
      
  def reset_rds_connection
     @rds = nil 
  end
  
  def mon_connection
       puts "environment.mon_connection"
       if @mon != nil
         return @mon
       else
        settings = @ec2_main.settings
        begin 
           @mon = RightAws::AcwInterface.new(settings.get('AMAZON_ACCESS_KEY_ID'), settings.get('AMAZON_SECRET_ACCESS_KEY'))
        rescue
          @mon = nil 
          puts "***Error on connection to Monitoring - check your keys"
          error_message(@ec2_main.tabBook,"Monitoring Connection Error",$!.to_s+" - check your EC2 Access Settings")
        end
        return @mon  
       end
  end
      
  def reset_mon_connection
    @mon = nil 
  end 
  
  def elb_connection
        puts "environment.elb_connection"
        if @elb != nil
          return @elb
        else
          settings = @ec2_main.settings
          if settings.get('EC2_PLATFORM') != nil and settings.get('EC2_PLATFORM') == "amazon" 
            begin
              if settings.get('EC2_URL') != nil and settings.get('EC2_URL').length>0
                elb_url = settings.get('EC2_URL')
                elb_url = elb_url.gsub("ec2.","")
                elb_url = elb_url.gsub("https://","https://elasticloadbalancing.")
                puts "Connecting to #{elb_url}" 
                @elb = RightAws::ElbInterface.new(settings.get('AMAZON_ACCESS_KEY_ID'), settings.get('AMAZON_SECRET_ACCESS_KEY'),  :endpoint_url => elb_url, :multi_thread => true)             
              else
                @elb = RightAws::ElbInterface.new(settings.get('AMAZON_ACCESS_KEY_ID'), settings.get('AMAZON_SECRET_ACCESS_KEY'), :multi_thread => true)
              end   
            rescue
              @elb = nil 
              puts "***Error on connection to ELB - check your keys"
              error_message(@ec2_main.tabBook,"Elastic Load Balancer Connection Error",$!.to_s+" - check your EC2 Access Settings")
            end
            return @elb  
          else
            @elb = nil 
            puts "***No Elastic Load Balancer unless Amazon platform"
          end 
       end
  end
        
  def reset_elb_connection
      @elb = nil 
  end 
 
 
def cf_connection
          puts "environment.cf_connection"
          if @cf != nil
            return @cf
          else
            settings = @ec2_main.settings
            if settings.get('EC2_PLATFORM') != nil and settings.get('EC2_PLATFORM') == "amazon" 
              begin
                ec2_url = settings.get('EC2_URL')
                if ec2_url != nil and ec2_url.length>0
                  region = "us-east-1"
                  sa = (ec2_url).split"."
		  if sa.size>1
		      region = (sa[1])
                  end
                  if region == "amazonaws"
                     region = "us-east-1"
                  end   
                  puts "Connecting to #{region}"  
                  @cf = Fog::AWS::CloudFormation.new(:aws_access_key_id => settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key =>settings.get('AMAZON_SECRET_ACCESS_KEY'), :region => region ) 
                else
                  @cf = Fog::AWS::CloudFormation.new(:aws_access_key_id => settings.get('AMAZON_ACCESS_KEY_ID'), :aws_secret_access_key =>settings.get('AMAZON_SECRET_ACCESS_KEY')) 
                end   
              rescue
                @cf = nil 
                puts "***Error on connection to Cloud Formation - check your keys"
                error_message(@ec2_main.tabBook,"Cloud Formation Connection Error",$!.to_s+" - check your EC2 Access Settings")
              end
              return @cf  
            else
              @cf = nil 
              puts "***No Cloud Formation unless Amazon platform"
            end 
         end
  end 
 
  def reset_cf_connection
      @cf = nil 
  end 
 
 
 
  def error_message(owner,title,message)
         FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
  def enable_if_env_set(sender)
         if @env != nil and @env.length>0 and @ec2_main.treeCache.status != "loading"
         	sender.enabled = true
         else
           sender.enabled = false
         end
  end
 
 def disable_if_env_loading(sender)
          if @ec2_main.treeCache.status != "loading"
            sender.enabled = true
          else
            sender.enabled = false
          end
 end
 
 
 def show_repository_loc
    loc = @settings.get_system("REPOSITORY_LOCATION")
    if loc !=  ENV['EC2DREAM_HOME']+"/env"
       @env_repository_loc.text = "Repository - "+loc+"   "
    else
       @env_repository_loc.text = " "
    end
 end          
 
 def browser(url)
        if @ec2_main.settings.get_system('EXTERNAL_BROWSER') != nil and @ec2_main.settings.get_system('EXTERNAL_BROWSER') != ""
           if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
              c = "cmd.exe /c \@start \"\" /b \""+@ec2_main.settings.get_system('EXTERNAL_BROWSER')+"\"  "+url
              puts c
              system(c)
           else
              c = @ec2_main.settings.get_system('EXTERNAL_BROWSER')+" "+url
              puts c
              system(c)
           end
        else
           error_message(@ec2_main,"Error","No External Browser in Settings")
        end
 end  
 
end  
