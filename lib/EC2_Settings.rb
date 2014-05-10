require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'dialog/EC2_KeypairDialog'
require 'dialog/EC2_ImageDialog'
require 'dialog/EC2_RegionsDialog'
require 'dialog/EC2_AvailZoneDialog'
require 'dialog/EC2_PlatformsDialog'
require 'dialog/EC2_TimezoneDialog'
require 'dialog/EC2_ShowPasswordDialog'
require 'dialog/EC2_SystemDialog'
require 'dialog/EC2_TerminalsDialog'
require 'dialog/EC2_BastionEditDialog'
require 'common/error_message'
require 'common/read_properties'
require 'common/save_properties'

class EC2_Settings

  def initialize(owner)
        puts "Settings.initialize"
        @ec2_main = owner
	@settings = {}
	@system_properties = {}
	@properties = {}
        @tags_filter = nil
 	@disk = @ec2_main.makeIcon("page_save.png")
	@disk.create
	@link = @ec2_main.makeIcon("link_break.png")
	@link.create
	@magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create
	@tunnel = @ec2_main.makeIcon("tunnel.png")
	@tunnel.create
    @repository = @ec2_main.makeIcon("drawer.png")
	@repository.create
	@puppet_icon = @ec2_main.makeIcon("puppet.png")
	@puppet_icon.create
	@chef_icon = @ec2_main.makeIcon("chef.png")
	@chef_icon.create
        tab4 = FXTabItem.new(@ec2_main.tabBook, " Environment ")
        page1 = FXVerticalFrame.new(@ec2_main.tabBook)
        page1a = FXHorizontalFrame.new(page1,LAYOUT_FILL_X, :padding => 0)
	@settings['SAVE_SETTINGS_BUTTON'] = FXButton.new(page1a, "Save Settings", :opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@settings['SAVE_SETTINGS_BUTTON'].icon = @disk
	@settings['SAVE_SETTINGS_BUTTON'].tipText = "Save Settings"
	@settings['SAVE_SETTINGS_BUTTON'].connect(SEL_COMMAND) do
	 save
	 save_system_screen_values
	end
	@settings['SAVE_SETTINGS_BUTTON'].connect(SEL_UPDATE) do |sender, sel, data|
	    enable_if_env_set(sender)
    	end
        if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
	   @settings['PUTTY_GENERATE_BUTTON'] = FXButton.new(page1a, "PuTTygen Key Generator", :opts => BUTTON_NORMAL|LAYOUT_LEFT)
	   @settings['PUTTY_GENERATE_BUTTON'].icon = @link
	   @settings['PUTTY_GENERATE_BUTTON'].tipText = " PuTTYgen Key Generator"
	   FXLabel.new(page1a, "In PuTTYgen press OK and then press SAVE PRIVATE KEY" )
	   @settings['PUTTY_GENERATE_BUTTON'].connect(SEL_COMMAND) do
	      puts "settings.PuttyGenerateButton.connect"
	      if @settings['EC2_SSH_PRIVATE_KEY'].text != nil and @settings['EC2_SSH_PRIVATE_KEY'].text != ''
	         system("cmd.exe /C "+ENV['EC2DREAM_HOME']+"/putty//puttygen "+"\""+@settings['EC2_SSH_PRIVATE_KEY'].text+"\""+"  -t rsa")
	      else
	         error_message("Error","No EC2_SSH_PRIVATE_KEY setting specified")
	      end
           end
           @settings['PUTTY_GENERATE_BUTTON'].connect(SEL_UPDATE) do |sender, sel, data|
	       	    enable_if_env_set(sender)
    	   end
    	end

        frame1 = FXMatrix.new(page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
		       FXLabel.new(frame1, "ENVIRONMENT" )
	@settings['ENV_NAME'] = FXTextField.new(frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
		       FXLabel.new(frame1, "ENV_REPOSITORY" )
	@settings['REPOSITORY_LOCATION'] = FXTextField.new(frame1, 60, nil, 0, :opts => TEXTFIELD_READONLY)
	@settings['REPOSITORY_LOCATION_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['REPOSITORY_LOCATION_BUTTON'].icon = @repository
	@settings['REPOSITORY_LOCATION_BUTTON'].tipText = "Select..."
	@settings['REPOSITORY_LOCATION_BUTTON'].connect(SEL_COMMAND) do
		   if @ec2_main.treeCache.status != "loading"
              dialog = EC2_SystemDialog.new(@ec2_main)
              dialog.execute(PLACEMENT_DEFAULT)
              if dialog.selected
				loc = get_system("REPOSITORY_LOCATION")
				if loc !=  ENV['EC2DREAM_HOME']+"/env"
					@settings['REPOSITORY_LOCATION'].text = "#{loc}"
				else
					@settings['REPOSITORY_LOCATION'].text = " "
				end
				FXMessageBox.warning(@ec2_main,MBOX_OK,"REPOSITORY_LOCATION","Restart to use new repository")
              end
           end
        end
        #
        #  Amazon EC2 Access Settings
        #
    	FXLabel.new(frame1, "" )
        FXLabel.new(frame1, "  Cloud Access Settings", nil, LAYOUT_CENTER_X)
        FXLabel.new(frame1, "" )
        FXLabel.new(frame1, "PLATFORM" )
	@settings['EC2_PLATFORM'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	@settings['EC2_PLATFORM_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['EC2_PLATFORM_BUTTON'].icon = @magnifier
	@settings['EC2_PLATFORM_BUTTON'].tipText = "Select..."
	@settings['EC2_PLATFORM_BUTTON'].connect(SEL_COMMAND) do
            dialog = EC2_PlatformsDialog.new(@ec2_main)
            dialog.execute
            it = dialog.selected
            if it != nil and it != ""
               @settings['EC2_PLATFORM'].text = it
            end
        end
	@settings['AMAZON_ACCESS_KEY_ID_LABEL'] = FXLabel.new(frame1, "ACCESS_KEY_ID" )
	@settings['AMAZON_ACCESS_KEY_ID'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
 	FXLabel.new(frame1, "" )
 	@settings['AMAZON_SECRET_ACCESS_KEY_LABEL'] = FXLabel.new(frame1, "SECRET_ACCESS_KEY" )
	@settings['AMAZON_SECRET_ACCESS_KEY'] = FXTextField.new(frame1, 60, nil, 0, :opts => TEXTFIELD_PASSWD|FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	@settings['AMAZON_SECRET_ACCESS_KEY_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['AMAZON_SECRET_ACCESS_KEY_BUTTON'].icon = @magnifier
	@settings['AMAZON_SECRET_ACCESS_KEY_BUTTON'].tipText = "Show Secret Access Key"
	@settings['AMAZON_SECRET_ACCESS_KEY_BUTTON'].connect(SEL_COMMAND) do
	   dialog = EC2_ShowPasswordDialog.new(@ec2_main,"AMAZON_SECRET_ACCESS_KEY",@settings['AMAZON_SECRET_ACCESS_KEY'].text)
           dialog.execute
	end
    @settings['AMAZON_ACCOUNT_ID_LABEL'] = FXLabel.new(frame1, "ACCOUNT_ID" )
	@settings['AMAZON_ACCOUNT_ID'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	FXLabel.new(frame1, "" )
 	@settings['EC2_URL_LABEL'] = FXLabel.new(frame1, "URL" )
	@settings['EC2_URL'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	@settings['EC2_URL_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['EC2_URL_BUTTON'].icon = @magnifier
	@settings['EC2_URL_BUTTON'].tipText = "Select..."
	@settings['EC2_URL_BUTTON'].connect(SEL_COMMAND) do
            dialog = EC2_RegionsDialog.new(@ec2_main,"EC2",@settings['EC2_PLATFORM'].text)
            dialog.execute
            it = dialog.selected
            if it != nil and it != ""
               @settings['EC2_URL'].text = it
            end
        end
    @settings['AVAILABILITY_ZONE_LABEL'] = FXLabel.new(frame1, "AVAILABILITY_ZONE" )
	@settings['AVAILABILITY_ZONE'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	@settings['AVAILABILITY_ZONE_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['AVAILABILITY_ZONE_BUTTON'].icon = @magnifier
	@settings['AVAILABILITY_ZONE_BUTTON'].tipText = "Select..."
	@settings['AVAILABILITY_ZONE_BUTTON'].connect(SEL_COMMAND) do
            dialog = EC2_AvailZoneDialog.new(@ec2_main,@settings['EC2_PLATFORM'].text)
            dialog.execute
            it = dialog.selected
            if it != nil and it != ""
               @settings['AVAILABILITY_ZONE'].text = it
            end
        end
    @settings['AMAZON_NICKNAME_TAG'] = FXLabel.new(frame1, "NICKNAME TAG" )
	@settings['AMAZON_NICKNAME_TAG'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
        FXLabel.new(frame1, "" )
 	#
	#   PuTTY and WinSCP Settings
        #
        FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "  PuTTY, ssh and SCP Settings", nil, LAYOUT_CENTER_X)
	FXLabel.new(frame1, "" )
        FXLabel.new(frame1, "SSH_PRIVATE_KEY" )
	@settings['EC2_SSH_PRIVATE_KEY'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	@settings['EC2_SSH_PRIVATE_KEY_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['EC2_SSH_PRIVATE_KEY_BUTTON'].icon = @magnifier
	@settings['EC2_SSH_PRIVATE_KEY_BUTTON'].tipText = "Browse..."
	@settings['EC2_SSH_PRIVATE_KEY_BUTTON'].connect(SEL_COMMAND) do
	   dialog = FXFileDialog.new(frame1, "Select pem file")
	   dialog.patternList = [
	          "Pem Files (*.pem)"
	   ]
	   dialog.selectMode = SELECTFILE_EXISTING
	   if dialog.execute != 0
	      @settings['EC2_SSH_PRIVATE_KEY'].text = dialog.filename
	   end
	end
        if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
	   FXLabel.new(frame1, "PUTTY_PRIVATE_KEY" )
	   @settings['PUTTY_PRIVATE_KEY'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
 	   @settings['PUTTY_PRIVATE_KEY_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	   @settings['PUTTY_PRIVATE_KEY_BUTTON'].icon = @magnifier
	   @settings['PUTTY_PRIVATE_KEY_BUTTON'].tipText = "Browse..."
	   @settings['PUTTY_PRIVATE_KEY_BUTTON'].connect(SEL_COMMAND) do
	      dialog = FXFileDialog.new(frame1, "Select pem file")
	      dialog.patternList = [
	          "Pem Files (*.ppk)"
	      ]
	      dialog.selectMode = SELECTFILE_EXISTING
	      if dialog.execute != 0
	         @settings['PUTTY_PRIVATE_KEY'].text = dialog.filename
	      end
	   end
	end
	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "" )
	@settings['BASTION_BUTTON'] = FXButton.new(frame1, "  Configure Bastion Host  ", :opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@settings['BASTION_BUTTON'].icon = @tunnel
	@settings['BASTION_BUTTON'].tipText = "  Configure Bastion Host  "
	@settings['BASTION_BUTTON'].connect(SEL_COMMAND) do
	   r = {}
	   r['bastion_host'] = @properties['BASTION_HOST']
	   r['bastion_port'] = @properties['BASTION_PORT']
	   r['bastion_user'] = @properties['BASTION_USER']
	   r['bastion_ssh_key'] = @properties['BASTION_SSH_KEY']
           r['bastion_putty_key'] = @properties['BASTION_PUTTY_KEY']
	   dialog = EC2_BastionEditDialog.new(@ec2_main,r)
	   dialog.execute
	   if dialog.saved
	      r = dialog.selected
	      if r != nil and r != ""
	         @properties['BASTION_HOST']=r['bastion_host']
	         @properties['BASTION_PORT']=r['bastion_port']
	         @properties['BASTION_USER']=r['bastion_user']
	         @properties['BASTION_SSH_KEY']=r['bastion_ssh_key']
                 @properties['BASTION_PUTTY_KEY']=r['bastion_putty_key']
                 save
              end
	   end
	end

	FXLabel.new(frame1, "" )
	#
	#   Global and General Settings
    #
    FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "  Global and General Settings", nil, LAYOUT_CENTER_X)
	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "CHEF_REPOSITORY" )
 	@settings['CHEF_REPOSITORY'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
 	@settings['CHEF_REPOSITORY_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['CHEF_REPOSITORY_BUTTON'].icon = @magnifier
	@settings['CHEF_REPOSITORY_BUTTON'].tipText = "Browse..."
	@settings['CHEF_REPOSITORY_BUTTON'].connect(SEL_COMMAND) do
	   dialog = FXDirDialog.new(frame1, "Select Chef Repository Directory")
	   if @settings['CHEF_REPOSITORY'].text==nil or @settings['CHEF_REPOSITORY'].text==""
              dialog.directory = "#{ENV['EC2DREAM_HOME']}/chef/chef-repo"
           else
              dialog.directory = @settings['CHEF_REPOSITORY'].text
           end
	   if dialog.execute != 0
	      @settings['CHEF_REPOSITORY'].text = dialog.directory
           end
	end
	FXLabel.new(frame1, "PUPPET_REPOSITORY" )
 	@settings['PUPPET_REPOSITORY'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
 	@settings['PUPPET_REPOSITORY_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['PUPPET_REPOSITORY_BUTTON'].icon = @magnifier
	@settings['PUPPET_REPOSITORY_BUTTON'].tipText = "Browse..."
	@settings['PUPPET_REPOSITORY_BUTTON'].connect(SEL_COMMAND) do
	   dialog = FXDirDialog.new(frame1, "Select Puppet Repository Directory")
	   if @settings['PUPPET_REPOSITORY'].text==nil or @settings['PUPPET_REPOSITORY'].text==""
              dialog.directory = "#{ENV['EC2DREAM_HOME']}/puppet/puppet_repo"
           else
              dialog.directory = @settings['PUPPET_REPOSITORY'].text
           end
	   if dialog.execute != 0
	      @settings['PUPPET_REPOSITORY'].text = dialog.directory
            end
	end
	FXLabel.new(frame1, "TEST_KITCHEN_PATH" )
 	@settings['TEST_KITCHEN_PATH'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
 	@settings['TEST_KITCHEN_PATH_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['TEST_KITCHEN_PATH_BUTTON'].icon = @magnifier
	@settings['TEST_KITCHEN_PATH_BUTTON'].tipText = "Browse..."
	@settings['TEST_KITCHEN_PATH_BUTTON'].connect(SEL_COMMAND) do
	   dialog = FXDirDialog.new(frame1, "Select Test Kitchen Path")
	   if @settings['TEST_KITCHEN_PATH'].text==nil or @settings['TEST_KITCHEN_PATH'].text==""
              dialog.directory = "#{ENV['EC2DREAM_HOME']}/chef/chef-repo/site-cookbooks/mycompany_webserver"
           else
              dialog.directory = @settings['TEST_KITCHEN_PATH'].text
           end
	   if dialog.execute != 0
	      @settings['TEST_KITCHEN_PATH'].text = dialog.directory
           end
	end
	FXLabel.new(frame1, "VAGRANT_REPOSITORY" )
 	@settings['VAGRANT_REPOSITORY'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
 	@settings['VAGRANT_REPOSITORY_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['VAGRANT_REPOSITORY_BUTTON'].icon = @magnifier
	@settings['VAGRANT_REPOSITORY_BUTTON'].tipText = "Browse..."
	@settings['VAGRANT_REPOSITORY_BUTTON'].connect(SEL_COMMAND) do
	   dialog = FXDirDialog.new(frame1, "Select Vagrant Repository Directory")
	   if @settings['VAGRANT_REPOSITORY'].text==nil or @settings['VAGRANT_REPOSITORY'].text==""
               dialog.directory = "#{ENV['EC2DREAM_HOME']}/vagrant"
           else
              dialog.directory = @settings['VAGRANT_REPOSITORY'].text
           end

	   if dialog.execute != 0
	      @settings['VAGRANT_REPOSITORY'].text = dialog.directory
           end
	end
	FXLabel.new(frame1, "CLOUD_ADMIN_URL" )
	@settings['CLOUD_ADMIN_URL'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
        FXLabel.new(frame1, "" )
	if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
	   FXLabel.new(frame1, "TERMINAL_EMULATOR" )
           @settings['TERMINAL_EMULATOR'] = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
           @settings['TERMINAL_EMULATOR'].text = "xterm"
	   @settings['TERMINAL_EMULATOR_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	   @settings['TERMINAL_EMULATOR_BUTTON'].icon = @magnifier
	   @settings['TERMINAL_EMULATOR_BUTTON'].tipText = "Select..."
	   @settings['TERMINAL_EMULATOR_BUTTON'].connect(SEL_COMMAND) do
              dialog = EC2_TerminalsDialog.new(@ec2_main)
              dialog.execute
              it = dialog.selected
              if it != nil and it != ""
                 @settings['EC2_PLATFORM'].text = it
              end
           end
        end
        FXLabel.new(frame1, "EXTERNAL_EDITOR" )
	@settings['EXTERNAL_EDITOR'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
       	@settings['EXTERNAL_EDITOR_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['EXTERNAL_EDITOR_BUTTON'].icon = @magnifier
	@settings['EXTERNAL_EDITOR_BUTTON'].tipText = "Browse..."
	@settings['EXTERNAL_EDITOR_BUTTON'].connect(SEL_COMMAND) do
	   dialog = FXFileDialog.new(frame1, "Select External Editor")
	   dialog.patternList = [
	          "All Files (*.*)"
	   ]
	   dialog.selectMode = SELECTFILE_EXISTING
	   if dialog.execute != 0
	      @settings['EXTERNAL_EDITOR'].text = dialog.filename
	   end
	end
	FXLabel.new(frame1, "EXTERNAL_BROWSER" )
	@settings['EXTERNAL_BROWSER'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	@settings['EXTERNAL_BROWSER_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['EXTERNAL_BROWSER_BUTTON'].icon = @magnifier
	@settings['EXTERNAL_BROWSER_BUTTON'].tipText = "Browse..."
	@settings['EXTERNAL_BROWSER_BUTTON'].connect(SEL_COMMAND) do
	   dialog = FXFileDialog.new(frame1, "Select External Browser")
	   dialog.patternList = [
	          "All Files (*.*)"
	   ]
	   dialog.selectMode = SELECTFILE_EXISTING
	   if dialog.execute != 0
	      @settings['EXTERNAL_BROWSER'].text = dialog.filename
	   end
	end
	FXLabel.new(frame1, "TIMEZONE" )
	@settings['TIMEZONE'] = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	@settings['TIMEZONE_BUTTON'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@settings['TIMEZONE_BUTTON'].icon = @magnifier
	@settings['TIMEZONE_BUTTON'].tipText = "Browse..."
	@settings['TIMEZONE_BUTTON'].connect(SEL_COMMAND) do
	   dialog = EC2_TimezoneDialog.new(@ec2_main)
	   dialog.execute
	   timezone = dialog.selected
	   if timezone != nil and timezone != ""
	       @settings['TIMEZONE'].text = timezone
	   end
	end

  end



  def load
     puts "Settings.load"
     @properties = {}
     ENV['EC2_ENVIRONMENT']=@system_properties['ENVIRONMENT']
     clear_panel
	 @settings['ENV_NAME'].text = get_system("ENVIRONMENT")
	loc = get_system("REPOSITORY_LOCATION")
    if loc !=  ENV['EC2DREAM_HOME']+"/env"
        @settings['REPOSITORY_LOCATION'].text = "#{loc}"
    else
        @settings['REPOSITORY_LOCATION'].text = " "
    end
     env_path = get_system('ENV_PATH')
     if File.exists?(env_path+"/env.properties")
        @properties=read_properties(env_path+"/env.properties",true)
	load_panel('EC2_PLATFORM')
        @settings['EC2_PLATFORM'].text =  (@settings['EC2_PLATFORM'].text).downcase  if @settings['EC2_PLATFORM'].text != nil or @settings['EC2_PLATFORM'].text = ""
	@properties['EC2_PLATFORM'] = @properties['EC2_PLATFORM'].downcase  if @properties['EC2_PLATFORM'] != nil or @properties['EC2_PLATFORM'] = ""
        load_panel('EC2_URL')
        load_panel('EC2_SSH_PRIVATE_KEY')
        load_panel('AMAZON_ACCOUNT_ID')
        load_panel('AMAZON_ACCESS_KEY_ID')
        load_panel('AMAZON_SECRET_ACCESS_KEY')
	load_panel('CHEF_REPOSITORY')
	load_panel('PUPPET_REPOSITORY')
	load_panel('TEST_KITCHEN_PATH')
	if @settings['TEST_KITCHEN_PATH'].text == nil or @settings['TEST_KITCHEN_PATH'].text == ""
	   @properties['TEST_KITCHEN_PATH']  = "#{ENV['EC2DREAM_HOME']}/chef/chef-repo/site-cookbooks/mycompany_webserver"
	   @settings['TEST_KITCHEN_PATH'].text = "#{ENV['EC2DREAM_HOME']}/chef/chef-repo/site-cookbooks/mycompany_webserver"
        end
        load_panel('VAGRANT_REPOSITORY')
        if @settings['VAGRANT_REPOSITORY'].text == nil or @settings['VAGRANT_REPOSITORY'].text == ""
           @properties['VAGRANT_REPOSITORY']  = "#{ENV['EC2DREAM_HOME']}/chef/vagrant"
           @settings['VAGRANT_REPOSITORY'].text = "#{ENV['EC2DREAM_HOME']}/chef/vagrant"
        end
        load_panel('AVAILABILITY_ZONE')
        load_panel('AMAZON_NICKNAME_TAG')
        if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
           load_panel('TERMINAL_EMULATOR')
        end
        @settings['EXTERNAL_EDITOR'].text = get_system('EXTERNAL_EDITOR')
        @settings['EXTERNAL_BROWSER'].text = get_system('EXTERNAL_BROWSER')
        @settings['TIMEZONE'].text = get_system('TIMEZONE')
	    if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
          load_panel('PUTTY_PRIVATE_KEY')
        end
        load_panel('CLOUD_ADMIN_URL')
		if @settings['EC2_PLATFORM'].text=="google"
			@settings['AMAZON_ACCESS_KEY_ID_LABEL'].text="CLIENT_EMAIL"
			@settings['AMAZON_SECRET_ACCESS_KEY_LABEL'].text="KEY_LOCATION"
			@settings['AMAZON_ACCOUNT_ID_LABEL'].text=""
		    @settings['EC2_URL_LABEL'].text="PROJECT"
			@settings['AVAILABILITY_ZONE_LABEL'].text = "ZONE"
			@settings['AMAZON_NICKNAME_TAG'].text=""
		else
			@settings['AMAZON_ACCESS_KEY_ID_LABEL'].text="ACCESS_KEY"
			@settings['AMAZON_SECRET_ACCESS_KEY_LABEL'].text="SECRET_ACCESS_KEY"
			@settings['AMAZON_ACCOUNT_ID_LABEL'].text="ACCOUNT_ID"
		    @settings['EC2_URL_LABEL'].text="URL"
			@settings['AVAILABILITY_ZONE_LABEL'].text = "AVAILABILITY_ZONE"
            @settings['AMAZON_NICKNAME_TAG'].text="NICKNAME TAG"
	    end
     end
     @ec2_main.app.forceRefresh
  end

  def load_panel(key)
   puts "Settings.load_panel "+key
   if @properties[key] != nil
      @settings[key].text = @properties[key]
   end
  end

  def clear_panel
    clear('ENV_NAME')
    clear('REPOSITORY_LOCATION')
    clear('EC2_PLATFORM')
    clear('EC2_URL')
    clear('EC2_SSH_PRIVATE_KEY')
    clear('AMAZON_ACCOUNT_ID')
    clear('AMAZON_ACCESS_KEY_ID')
    clear('AMAZON_SECRET_ACCESS_KEY')
    clear('CHEF_REPOSITORY')
    clear('PUPPET_REPOSITORY')
    clear('TEST_KITCHEN_PATH')
    clear('VAGRANT_REPOSITORY')
    clear('AVAILABILITY_ZONE')
    clear('AMAZON_NICKNAME_TAG')
    clear('EXTERNAL_EDITOR')
    clear('EXTERNAL_BROWSER')
    clear('TIMEZONE')
    if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
       clear('PUTTY_PRIVATE_KEY')
    end
    if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
       @settings['TERMINAL_EMULATOR'].text = "xterm"
    end
    clear('CLOUD_ADMIN_URL')
  end

  def clear(key)
    @settings[key].text = ""
    if key.index("EC2_")==0 or key.index("AMAZON_")==0 or key.index("S3_")==0
     ENV[key]=""
    end
  end

  def get(key)
     #puts "Settings.get #{key}"
     if @properties[key] != nil
        return @properties[key]
     else
        return ""
     end
  end

  def amazon
       if get("EC2_PLATFORM") == "amazon"
         return true
       else
         return false
       end
  end

  def google
       if get("EC2_PLATFORM") == "google"
         return true
       else
         return false
       end
  end

 def cloudstack
       if get("EC2_PLATFORM") == "cloudstack"
         return true
       else
         return false
       end
  end

  def eucalyptus
       if get("EC2_PLATFORM") == "eucalyptus"
         return true
       else
         return false
       end
  end

  #def openstack
  #   if get("EC2_PLATFORM").start_with?("openstack")
  #     return true
  #   else
  #     return false
  #   end
  #end

  def openstack
      begin
       if $ec2_main.cloud.api == 'openstack'
          true
       else
          false
       end
	  rescue
	   false
	  end
  end

 def aws
     begin
       if $ec2_main.cloud.api == 'aws'
          true
       else
          false
       end
	 rescue
       false
     end
  end

  def openstack_hp
       if get("EC2_PLATFORM") == "openstack_hp"
         return true
       else
         return false
       end
  end

  def openstack_rackspace
       if get("EC2_PLATFORM") == "openstack_rackspace"
         return true
       else
         return false
       end
  end

  def cloudfoundry
       if get("EC2_PLATFORM") == "cloudfoundry"
         return true
       else
         return false
       end
  end

  def put(key,value)
     puts "Settings.put"
     @properties[key] = value
     begin
        @settings[key].text = value
     rescue
     end
     if key.index("EC2_")==0 or key.index("AMAZON_")==0 or key.index("S3_")==0
       ENV[key] = value
     end
  end

  def save
     puts "Settings.save"
     @settings['EC2_PLATFORM'].text = (@settings['EC2_PLATFORM'].text).downcase
     save_setting('EC2_PLATFORM')
     save_setting("EC2_URL")
     save_setting("EC2_SSH_PRIVATE_KEY")
     save_setting("AMAZON_ACCOUNT_ID")
     save_setting("AMAZON_ACCESS_KEY_ID")
     save_setting("AMAZON_SECRET_ACCESS_KEY")
     save_setting("CHEF_REPOSITORY")
     save_setting("PUPPET_REPOSITORY")
     save_setting("TEST_KITCHEN_PATH")
     save_setting("VAGRANT_REPOSITORY")
     save_setting("AVAILABILITY_ZONE")
     save_setting("AMAZON_NICKNAME_TAG")
     if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
        save_setting("PUTTY_PRIVATE_KEY")
     end
     save_setting("CLOUD_ADMIN_URL")
     env_path = get_system('ENV_PATH')
     save_properties(@properties,env_path+"/env.properties")
     @ec2_main.environment.reset_connection
  end

  def save_system_screen_values
     if RUBY_PLATFORM.index("mswin") == nil and RUBY_PLATFORM.index("i386-mingw32") == nil
        put_system("TERMINAL_EMULATOR",@settings["TERMINAL_EMULATOR"].text)
     end
     put_system("EXTERNAL_EDITOR",@settings["EXTERNAL_EDITOR"].text)
     put_system("EXTERNAL_BROWSER",@settings["EXTERNAL_BROWSER"].text)
     put_system("TIMEZONE",@settings["TIMEZONE"].text)
     save_system()
  end

  def save_setting(key)
    puts "Settings.save_setting "+key
    if @settings[key].text != nil
      @properties[key] =  @settings[key].text
    else
      @properties[key] = nil
    end
    if key.index("EC2_")==0 or key.index("AMAZON_")==0 or key.index("S3_")==0
       ENV[key]=@properties[key]
    end
  end


  #
  # System property settings
  #

   def load_system
       puts "Settings.load_system"
       begin
          @system_properties = read_properties(ENV['EC2DREAM_HOME']+"/env/system.properties")
       rescue
          {}
       end
    end

    def get_system(key)
         #puts "Settings.get_system "+key
         r = nil
         if key == "ENV_PATH"
            loc = @system_properties["REPOSITORY_LOCATION"]
            if loc == nil or loc == ""
              r = ENV['EC2DREAM_HOME']+"/env/"+@system_properties['ENVIRONMENT']
            else
              r = loc +"/"+@system_properties['ENVIRONMENT']
            end
         else
            if key == "REPOSITORY_LOCATION"
               r = @system_properties["REPOSITORY_LOCATION"]
               if r == nil or r == ""
                  r = ENV['EC2DREAM_HOME']+"/env"
               end
               @settings['REPOSITORY_LOCATION'].text = r
            else
              r = @system_properties[key]
            end
         end
         return r
    end

    def put_system(key, value)
        puts "Settings.put_system "+key
        if key != nil
          @system_properties[key] =  value
        end
        if key == 'EXTERNAL_EDITOR'
           @settings['EXTERNAL_EDITOR'].text = value
        end
        if key == 'EXTERNAL_BROWSER'
           @settings['EXTERNAL_BROWSER'].text = value
        end
        if key == 'TIMEZONE'
           @settings['TIMEZONE'].text = value
        end
    end

    def save_system()
        puts "Settings.save_system"
        save_properties(@system_properties,ENV['EC2DREAM_HOME']+"/env/system.properties")
    end

  #
  # Filter property settings
  #
    def save_filter(tags)
       @tags_filter = tags
       env_path = get_system('ENV_PATH')
       File.open(env_path+"/filter_save.rb", "w") do |f|
          Marshal.dump(@tags_filter , f)
       end
    end

    def load_filter()
      if @tags_filter == nil
         env_path = get_system('ENV_PATH')
         if File.exists?(env_path+"/filter_save.rb")
            open(env_path+"/filter_save.rb") do |f|
               @tags_filter = Marshal.load(f)
            end
         else
            @tags_filter = {}
         end
      end
      return @tags_filter
    end

    def enable_if_env_set(sender)
            @env = @ec2_main.environment.env
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

end
