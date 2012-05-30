
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'fileutils'
require 'zip/zip'
require 'zip/zipfilesystem'
#require 'ftools'
require 'fileutils'

require 'dialog/EC2_RegionsDialog'

include Fox

class EC2_EnvCreateDialog < FXDialogBox

  def initialize(owner)

    def textBox(label, frame)
      FXLabel.new(frame, label )
      pushback = FXTextField.new(frame, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
      FXLabel.new(frame, "" )
      return pushback
    end

    puts "EnvCreateDialog.initialize"
    @ec2_main = owner
    @ec2 = nil
    @env = ""
    @created = false
    @ec2_platform = "amazon"
    super(owner, "Create Environment", :opts => DECOR_ALL, :width => 600, :height => 250)

    mainFrame = FXVerticalFrame.new(self,LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)

    topFrame = FXVerticalFrame.new(mainFrame,LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)

    @tabbook = FXTabBook.new(topFrame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)

    @amazontab = FXTabItem.new(@tabbook, "&Amazon EC2", nil)
    @amazonframe = FXHorizontalFrame.new(@tabbook )

    frame1 = FXMatrix.new(@amazonframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)

    amazon_env = textBox("Environment Name",frame1)
    @amazon_access_key = textBox("Amazon Access Key",frame1)
    
    FXLabel.new(frame1, "Amazon Secret Access Key" )
    @amazon_secret_access_key = FXTextField.new(frame1, 40, nil, 0, :opts => TEXTFIELD_PASSWD|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame1, "" )
    
    if ENV['AMAZON_ACCESS_KEY_ID'] != nil and ENV['AMAZON_ACCESS_KEY_ID'] != ""
         @amazon_access_key.text = ENV['AMAZON_ACCESS_KEY_ID']
    end
    if ENV['AMAZON_SECRET_ACCESS_KEY'] != nil and ENV['AMAZON_SECRET_ACCESS_KEY'] != ""
         @amazon_secret_access_key.text = ENV['AMAZON_SECRET_ACCESS_KEY']
    end
    FXLabel.new(frame1, "Region (Default US-Virginia)" )
    @ec2_url = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @ec2_url.text = "https://ec2.us-east-1.amazonaws.com/"
    @ec2_url_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    @ec2_url_button.icon = @magnifier
    @ec2_url_button.tipText = "Select Region"
    @ec2_url_button.connect(SEL_COMMAND) do
       @dialog = EC2_RegionsDialog.new(@ec2_main,"EC2")
       @dialog.execute
       it = @dialog.selected
       if it != nil and it != ""
          @ec2_url.text = it
       end 
    end
    @eucatab = FXTabItem.new(@tabbook, "&Eucalyptus", nil)
    @eucaframe = FXHorizontalFrame.new(@tabbook)

    frame2 = FXMatrix.new(@eucaframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    
    euca_env = textBox("Environment Name",frame2)
    
    FXLabel.new(frame2, "Eucalyptus certificate zipfile" )
    @eucazipfile = FXTextField.new(frame2, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)

    open = FXButton.new(frame2, "", nil, self, ID_ACCEPT, BUTTON_TOOLBAR|LAYOUT_LEFT)
    open.icon = @magnifier
    open.connect(SEL_COMMAND) {
        eucazip = FXFileDialog.getOpenFilename(self, "Locate your eucalyptus certificate zipfile", "<eucalyptus certificate zipfile>", "*.zip")
        if eucazip
          @eucazipfile.text = eucazip
        end

    }
    @openstacktab = FXTabItem.new(@tabbook, "&OpenStack", nil)
    @openstackframe = FXHorizontalFrame.new(@tabbook )

    frame3 = FXMatrix.new(@openstackframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)

    openstack_env = textBox("Environment Name",frame3)
    @openstack_access_key = textBox("OpenStack User Name",frame3)
    
    FXLabel.new(frame3, "OpenStack Password" )
    @openstack_secret_access_key = FXTextField.new(frame3, 40, nil, 0, :opts => TEXTFIELD_PASSWD|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame3, "" )
    
    FXLabel.new(frame3, "OpenStack URL (Default Trystack)" )
    @openstack_url = FXTextField.new(frame3, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @openstack_url.text = "https://nova-api.trystack.org:5443"

    # cloudstack
    @cloudstacktab = FXTabItem.new(@tabbook, "&CloudStack", nil)
    @cloudstackframe = FXHorizontalFrame.new(@tabbook )

    frame4 = FXMatrix.new(@cloudstackframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)

    cloudstack_env = textBox("Environment Name",frame4)
    @cloudstack_access_key = textBox("CloudStack API Key",frame4)
    
    FXLabel.new(frame4, "CloudStack Secret Key" )
    @cloudstack_secret_access_key = FXTextField.new(frame4, 40, nil, 0, :opts => TEXTFIELD_PASSWD|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame4, "" )
    
    FXLabel.new(frame4, "CloudStack URL" )
    @cloudstack_url = FXTextField.new(frame4, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @cloudstack_url.text = "http://cloud-bridge-hostname:8090/bridge" 
    
    amazon_env.connect(SEL_CHANGED) {
      euca_env.text = amazon_env.text
      openstack_env.text = amazon_env.text
      cloudstack_env.text = amazon_env.text
      @new_env = amazon_env.text
    }
    
    euca_env.connect(SEL_CHANGED) {
      amazon_env.text = euca_env.text
      openstack_env.text = euca_env.text
      cloudstack_env.text = euca_env.text
      @new_env = euca_env.text
    }
    
    openstack_env.connect(SEL_CHANGED) {
      amazon_env.text = openstack_env.text
      euca_env.text = openstack_env.text
      cloudstack_env.text = openstack_env.text
      @new_env = openstack_env.text
    }
    
    cloudstack_env.connect(SEL_CHANGED) {
      amazon_env.text = cloudstack_env.text
      euca_env.text = cloudstack_env.text
      openstack_env.text = cloudstack_env.text
      @new_env = cloudstack_env.text
    }

    bottomFrame = FXVerticalFrame.new(mainFrame,LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    FXLabel.new(bottomFrame, "" )
    ok = FXButton.new(bottomFrame, "   &OK   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(bottomFrame, "" )
    ok.connect(SEL_COMMAND) do |sender, sel, data|
      @env = @new_env
      create_env
      if @created == true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end
  
  end 
  
 
  def create_env
   begin
    valid_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrisuvwxyz0123456789_"
    puts "CreateDialog.create_env "+ @env
    settings = @ec2_main.settings
    settings.load
    
    raise 'Environment Not Specified' if @env == nil or @env.length==0
    raise 'Environment Name must only contain A-Z, 0-9 or _ characters' if @env  =~ /\W/

    d = @ec2_main.settings.get_system('REPOSITORY_LOCATION')+"/"+@env
        
    raise 'Environment already exists' if File.exists?(d)
    
     
    Dir.mkdir(d)
    
    if @eucazipfile.text != ""
        unzip(@eucazipfile.text,d)
        eucarcpath = d+"/euca/eucarc"
        
        raise 'Not a valid Eucalyptus zipfile' unless File.exists?(eucarcpath)
        
        eucarc = File.open(eucarcpath, 'r')
        eucarc.read.each_line do |configline|
          if configline =~ /EC2_ACCESS_KEY=\'(\w+)\'/
            @amazon_access_key.text = $1
          end
          if configline =~ /EC2_SECRET_KEY=\'([^\']+)\'/
            @amazon_secret_access_key.text = $1
          end
          if configline =~ /EC2_URL=(.+)$/
            @ec2_url.text = $1
          end
        end
	@ec2_platform = "eucalyptus"
        eucarc.close
    end 
    if @openstack_access_key.text != ""
       @ec2_platform = "openstack"
       Dir.mkdir("#{d}/ops_secgrp")
       File.open("#{d}/ops_secgrp/default.properties", 'w') {|f| f.write("default") }
    end
    if @cloudstack_access_key.text != ""
       @ec2_platform = "cloudstack"
    end      
    Dir.mkdir(d+"/launch")
    save_env
    @created = true
    if  @ec2_platform == "cloudstack"
      if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil 
         message = "Exit EC2Dream and enter set EC2_API_VERSION=2010-11-15  before running ec2dream"
      else
         message = "Exit EC2Dream and enter export EC2_API_VERSION=2010-11-15  before running ec2dream"
      end    
      FXMessageBox.warning(self,MBOX_OK,"Restart EC2Dream",message)
    end    

   rescue Exception => error
      puts error.message
      FXMessageBox.warning(self,MBOX_OK,"Error",error.message)
   end
  end 
  
  def created 
     return @created
  end   
  

  def save_env
           puts "CreateDialog.save "+@env
           settings = @ec2_main.settings
           settings.put_system('ENVIRONMENT', @env)
           settings.put_system('AUTO', 'false')
           settings.save_system
           settings.load
	   settings.put("EC2_PLATFORM",@ec2_platform)
	   if @ec2_platform == "openstack"
              if @openstack_access_key.text != nil 
                 settings.put("AMAZON_ACCESS_KEY_ID",@openstack_access_key.text)
              end
              if @openstack_secret_access_key.text != nil 
                 settings.put("AMAZON_SECRET_ACCESS_KEY",@openstack_secret_access_key.text)
              end
              if @openstack_url.text != nil 
  	       settings.put("EC2_URL",@openstack_url.text)
  	      end
	   elsif @ec2_platform == "cloudstack"
              if @cloudstack_access_key.text != nil 
                 settings.put("AMAZON_ACCESS_KEY_ID",@cloudstack_access_key.text)
              end
              if @cloudstack_secret_access_key.text != nil 
                 settings.put("AMAZON_SECRET_ACCESS_KEY",@cloudstack_secret_access_key.text)
              end
              if @cloudstack_url.text != nil 
  	       settings.put("EC2_URL",@cloudstack_url.text)
  	      end  	      
	   else
              if @amazon_access_key.text != nil 
                 settings.put("AMAZON_ACCESS_KEY_ID",@amazon_access_key.text)
              end
              if @amazon_secret_access_key.text != nil 
                 settings.put("AMAZON_SECRET_ACCESS_KEY",@amazon_secret_access_key.text)
              end
              if @ec2_url.text != nil 
  	       settings.put("EC2_URL",@ec2_url.text)
  	      end
  	   end   
  	   settings.put('CLOUD_ADMIN_URL',"http://aws.amazon.com/ec2/")
  	   settings.put('CHEF_REPOSITORY',"#{ENV['EC2DREAM_HOME']}/chef/chef-repo")
           settings.save
  end
  
  def error_message(owner,title,message)
           FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end

  def unzip(eucazip,envpath)
    Dir.mkdir(envpath+"/euca")
    arch = Zip::ZipFile.open(eucazip)
    arch.each do |entry|
        xtrpath = File.join(envpath+"/euca/", entry.name)
        raise 'Eucalyptus zipfile in an unsupported format' if xtrpath =~ /euca\/.+\/.+/
        arch.extract(entry, xtrpath)
    end
  end

end
