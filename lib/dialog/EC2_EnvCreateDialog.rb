require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fileutils'
require 'zip/zip'
require 'zip/zipfilesystem'
require 'dialog/EC2_AvailZoneDialog'
require 'fileutils'

require 'dialog/EC2_RegionsDialog'

include Fox

class EC2_EnvCreateDialog < FXDialogBox

  def initialize(owner)

    puts "EnvCreateDialog.initialize"
    @ec2_main = owner
    @ec2 = nil
    @env = ""
    @created = false
    @ec2_platform = "amazon"
    super(owner, "Create Environment", :opts => DECOR_ALL, :width => 900, :height => 275)
    mainFrame = FXVerticalFrame.new(self,LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)
    topFrame = FXVerticalFrame.new(mainFrame,LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)
    @tabbook = FXTabBook.new(topFrame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)

    #
    # servers
    #
    @serverstab = FXTabItem.new(@tabbook, "&Servers", nil)
    @serverstab.tipText = "Local or Remote Servers accessible by IP address"
    @serversframe = FXHorizontalFrame.new(@tabbook )
    frame0 = FXMatrix.new(@serversframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame0,"")
    FXLabel.new(frame0,"")
    FXLabel.new(frame0,"")
    FXLabel.new(frame0,"")
    FXLabel.new(frame0,"")
    FXLabel.new(frame0,"")
    FXLabel.new(frame0,"")
    FXLabel.new(frame0,"")
    FXLabel.new(frame0,"")
    servers_env_label = FXLabel.new(frame0, "Environment Name" )
    servers_env_label.tipText = "A unique name to identified this environment in EC2Dream"
    servers_env = FXTextField.new(frame0, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame0, "" )

    #
    # amazon aws
    #
    @amazontab = FXTabItem.new(@tabbook, "&Amazon EC2", nil)
    @amazontab.tipText = "Amazon AWS Cloud"
    @amazonframe = FXHorizontalFrame.new(@tabbook )
    frame1 = FXMatrix.new(@amazonframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    amazon_env_label = FXLabel.new(frame1, "Environment Name" )
    amazon_env_label.tipText = "A unique name to identified this environment in EC2Dream"
    amazon_env = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )

    @amazon_access_key_label = FXLabel.new(frame1, "Amazon Access Key" )
    @amazon_access_key_label.tipText = "Your AWS account's access key id.\nUsed to access the AWS API."
    @amazon_access_key = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    @amazon_secret_access_key_label = FXLabel.new(frame1, "Amazon Secret Access Key" )
    @amazon_secret_access_key_label.tipText="Your AWS account's secret access key id.\nUsed to access the AWS API."
    @amazon_secret_access_key = FXTextField.new(frame1, 60, nil, 0, :opts => TEXTFIELD_PASSWD|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame1, "" )
    @ec2_url_label = FXLabel.new(frame1, "Region (Default US-Virginia)" )
    @ec2_url_label.tipText="The AWS Region you wish to access.\nEach Amazon EC2 region is completely isolated.\nCreate separate environments for multiple regions."
    @ec2_url = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @ec2_url_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    @ec2_url_button.icon = @magnifier
    @ec2_url_button.tipText = "Select Region"
    @ec2_url_button.connect(SEL_COMMAND) do
      @dialog = EC2_RegionsDialog.new(@ec2_main,"EC2","amazon")
      @dialog.execute
      it = @dialog.selected
      if it != nil and it != ""
        @ec2_url.text = it
      end
    end
    if ENV['AMAZON_ACCESS_KEY_ID'] != nil and ENV['AMAZON_ACCESS_KEY_ID'] != ""
      @amazon_access_key.text = ENV['AMAZON_ACCESS_KEY_ID']
    end
    if ENV['AMAZON_SECRET_ACCESS_KEY'] != nil and ENV['AMAZON_SECRET_ACCESS_KEY'] != ""
      @amazon_secret_access_key.text = ENV['AMAZON_SECRET_ACCESS_KEY']
    end
    @ec2_url.text = "https://ec2.us-east-1.amazonaws.com/"
    #
    # Google Compute Engine
    #
    @googletab = FXTabItem.new(@tabbook, "&Google Compute", nil)
    @googletab.tipText = "Google Compute Engine Cloud"
    @googleframe = FXHorizontalFrame.new(@tabbook )
    frame8 = FXMatrix.new(@googleframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    google_env_label = FXLabel.new(frame8, "Environment Name" )
    google_env_label.tipText = "A unique name to identified this environment in EC2Dream"
    google_env = FXTextField.new(frame8, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame8, "" )
    @google_client_email_label = FXLabel.new(frame8, "Google Client Email" )
    @google_client_email_label.tipText = "Your google email id"
    @google_client_email = FXTextField.new(frame8, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame8, "" )
    @google_key_location_label = FXLabel.new(frame8, "Google Key Location" )
    @google_key_location_label.tipText = "the location of your access key"
    @google_key_location = FXTextField.new(frame8, 60, nil, 0, :opts => TEXTFIELD_PASSWD|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    google_open = FXButton.new(frame8, "", nil, self, ID_ACCEPT, BUTTON_TOOLBAR|LAYOUT_LEFT)
    google_open.icon = @magnifier
    google_open.connect(SEL_COMMAND) {
      google_cert = FXFileDialog.getOpenFilename(self, "Locate your google certificate file", "<google certificate file>", "*.p12")
      if google_cert
        @google_key_location.text = google_cert
      end
    }
    @google_project_label = FXLabel.new(frame8, "Google Project" )
    @google_project_label.tipText = "All Google Compute Engine resources belong to a project. Projects form the basis for enabling and using the Google Cloud Platform services"
    @google_project = FXTextField.new(frame8, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame8, "" )
    @google_zone_label = FXLabel.new(frame8, "Google Zone" )
    @google_zone_label.tipText = "Google Compute Engine allows you to choose the region and zone where certain resources live. Zones are of the format <region>-<zone>"
    @google_zone = FXTextField.new(frame8, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @google_zone_button = FXButton.new(frame8, "", :opts => BUTTON_TOOLBAR)
    @google_zone_button.icon = @magnifier
    @google_zone_button.tipText = "Select Google Zone"
    @google_zone_button.connect(SEL_COMMAND) do
      @dialog = EC2_AvailZoneDialog.new(@ec2_main,"google")
      @dialog.execute
      it = @dialog.selected
      if it != nil and it != ""
        @google_zone.text = it
      end
    end
    if ENV['AMAZON_ACCESS_KEY_ID'] != nil and ENV['AMAZON_ACCESS_KEY_ID'] != ""
      @google_client_email.text = ENV['AMAZON_ACCESS_KEY_ID']
    end
    if ENV['AMAZON_SECRET_ACCESS_KEY'] != nil and ENV['AMAZON_SECRET_ACCESS_KEY'] != ""
      @google_key_location.text = ENV['AMAZON_SECRET_ACCESS_KEY']
    end
    @google_project.text = 'google.com:xxxxxxxxxxxx'
    if ENV['AVAILABILITY_ZONE'] != nil and ENV['AVAILABILITY_ZONE'] != ""
      @google_zone.text = ENV['AVAILABILITY_ZONE']
    else
      @google_zone.text = "us-central1-a"
    end

    #
    # openstack
    #
    @openstacktab = FXTabItem.new(@tabbook, "&OpenStack", nil)
    @openstacktab.tipText = "Openstack Cloud"
    @openstackframe = FXHorizontalFrame.new(@tabbook )
    frame3 = FXMatrix.new(@openstackframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    openstack_env_label = FXLabel.new(frame3, "Environment Name" )
    openstack_env_label.tipText = "A unique name to identified this environment in EC2Dream"
    openstack_env = FXTextField.new(frame3, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame3, "" )
    @openstack_access_key_label = FXLabel.new(frame3, "User Name" )
    @openstack_access_key_label.tipText = "Your Openstack user name."
    @openstack_access_key = FXTextField.new(frame3, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame3, "" )
    @openstack_secret_access_key_label = FXLabel.new(frame3, "Password" )
    @openstack_secret_access_key_label.tipText = "Your Openstack password."
    @openstack_secret_access_key = FXTextField.new(frame3, 60, nil, 0, :opts => TEXTFIELD_PASSWD|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame3, "" )
    @openstack_url_label = FXLabel.new(frame3, "URL (Default Trystack)" )
    @openstack_url_label.tipText = "Your Cloud's The OpenStack Identity or Nova URL Endpoint."
    @openstack_url = FXTextField.new(frame3, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame3, "" )
    @openstack_tenant_label = FXLabel.new(frame3, "Project" )
    @openstack_tenant_label.tipText = "The initial implementation of OpenStack Compute had its own authentication system and used the term project.\nWhen authentication moved into the OpenStack Identity (keystone) project, it used the term tenant to refer to a group of users.\nBecause of this legacy, some of the OpenStack tools refer to projects and some refer to tenants."
    @openstack_tenant = FXTextField.new(frame3, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    if ENV['AMAZON_ACCESS_KEY_ID'] != nil and ENV['AMAZON_ACCESS_KEY_ID'] != ""
      @openstack_access_key.text = ENV['AMAZON_ACCESS_KEY_ID']
    end
    if ENV['AMAZON_SECRET_ACCESS_KEY'] != nil and ENV['AMAZON_SECRET_ACCESS_KEY'] != ""
      @openstack_secret_access_key.text = ENV['AMAZON_SECRET_ACCESS_KEY']
    end
    #if ENV['EC2_URL'] != nil and ENV['EC2_URL'] != ""
    #    @openstack_url.text =  ENV['EC2_URL']
    #else
    @openstack_url.text = "https://nova-api.trystack.org:5443"
    #end
    if ENV['AMAZON_ACCOUNT_ID'] != nil and ENV['AMAZON_ACCOUNT_ID'] != ""
      @openstack_tenant.text = ENV['AMAZON_ACCOUNT_ID']
    end
    #
    # azure
    #
    @azuretab = FXTabItem.new(@tabbook, "&Azure", nil)
    @azuretab.tipText = "Azure"
    @azureframe = FXHorizontalFrame.new(@tabbook )
    frame4 = FXMatrix.new(@azureframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    azure_env_label = FXLabel.new(frame4, "Environment Name" )
    azure_env_label.tipText = "A unique name to identified this environment in EC2Dream"
    azure_env = FXTextField.new(frame4, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame4, "" )
    @azure_access_label = FXLabel.new(frame4, "Azure PEM Key Path" )
    @azure_access_label.tipText = "Path of Azure PEM Key."
    @azure_access_key = FXTextField.new(frame4, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame4, "" )
    @azure_subscription_id_label = FXLabel.new(frame4, "Azure Subscription Id" )
    @azure_subscription_id_label.tipText = "Azure Subscription Id."
    @azure_subscription_id = FXTextField.new(frame4, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame4, "" )
    @azure_url_label = FXLabel.new(frame4, "Azure URL" )
    @azure_url_label.tipText = "Azure Cloud API Endpoint"
    @azure_url = FXTextField.new(frame4, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    if ENV['AMAZON_ACCESS_KEY_ID'] != nil and ENV['AMAZON_ACCESS_KEY_ID'] != ""
      @azure_access_key.text = ENV['AMAZON_ACCESS_KEY_ID']
    end
    if ENV['AMAZON_ACCOUNT_ID'] != nil and ENV['AMAZON_ACCOUNT_ID'] != ""
      @azure_subscription_id.text = ENV['AMAZON_ACCOUNT_ID']
    end
    @azure_url.text = 'https://management.core.windows.net'
    # NOTE: if strings don't work for avail zones try symbols like :az1
    #
    # openstack_rackspace
    #
    @racktab = FXTabItem.new(@tabbook, "&Rackspace", nil)
    @racktab.tipText = "Rackspace Public Cloud"
    @rackframe = FXHorizontalFrame.new(@tabbook )
    frame5 = FXMatrix.new(@rackframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    rack_env_label = FXLabel.new(frame5, "Environment Name" )
    rack_env_label.tipText = "A unique name to identified this environment in EC2Dream"
    rack_env = FXTextField.new(frame5, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame5, "" )
    @rack_access_key_label = FXLabel.new(frame5, "Rackspace User Name" )
    @rack_access_key_label.tipText = "Your Rackspace Openstack user name."
    @rack_access_key = FXTextField.new(frame5, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame5, "" )
    @rack_secret_access_key_label = FXLabel.new(frame5, "Rackspace API Key" )
    @rack_secret_access_key_label.tipText = "Your Rackspace Openstack API Key"
    @rack_secret_access_key = FXTextField.new(frame5, 60, nil, 0, :opts => TEXTFIELD_PASSWD|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame5, "" )
    @rack_url_label = FXLabel.new(frame5, "Rackspace Endpoint (Default Dallas)" )
    @rack_url_label.tipText = "Used to identity the region to the rackspace API."
    @rack_url = FXTextField.new(frame5, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @rack_url_button = FXButton.new(frame5, "", :opts => BUTTON_TOOLBAR)
    @rack_url_button.icon = @magnifier
    @rack_url_button.tipText = "Select Region"
    @rack_url_button.connect(SEL_COMMAND) do
      @dialog = EC2_RegionsDialog.new(@ec2_main,"EC2","openstack_rackspace")
      @dialog.execute
      it = @dialog.selected
      if it != nil and it != ""
        @rack_url.text = it
      end
    end
    if ENV['AMAZON_ACCESS_KEY_ID'] != nil and ENV['AMAZON_ACCESS_KEY_ID'] != ""
      @rack_access_key.text = ENV['AMAZON_ACCESS_KEY_ID']
    end
    if ENV['AMAZON_SECRET_ACCESS_KEY'] != nil and ENV['AMAZON_SECRET_ACCESS_KEY'] != ""
      @rack_secret_access_key.text = ENV['AMAZON_SECRET_ACCESS_KEY']
    end
    @rack_url.text = "https://servers.api.rackspacecloud.com/v2"

    #
    # softlayer
    #
    @softlayertab = FXTabItem.new(@tabbook, "&Softlayer", nil)
    @softlayerframe = FXHorizontalFrame.new(@tabbook )
    frame6 = FXMatrix.new(@softlayerframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    softlayer_env_label = FXLabel.new(frame6, "Environment Name" )
    softlayer_env_label.tipText = "A unique name to identified this environment in EC2Dream"
    softlayer_env = FXTextField.new(frame6, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame6, "" )
    @softlayer_access_key_label = FXLabel.new(frame6, "Softlayer Username" )
    @softlayer_access_key_label.tipText = "Your Softlayer account's username.\nUsed to access the Softlayer API."
    @softlayer_access_key = FXTextField.new(frame6, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame6, "" )
    @softlayer_secret_access_key_label = FXLabel.new(frame6, "Softlayer API Key" )
    @softlayer_secret_access_key_label.tipText = "Your Softlayer account's API Key.\nUsed to access the Softlayer API."
    @softlayer_secret_access_key = FXTextField.new(frame6, 60, nil, 0, :opts => TEXTFIELD_PASSWD|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame6, "" )
    if ENV['AMAZON_ACCESS_KEY_ID'] != nil and ENV['AMAZON_ACCESS_KEY_ID'] != ""
      @softlayer_access_key.text = ENV['AMAZON_ACCESS_KEY_ID']
    end
    if ENV['AMAZON_SECRET_ACCESS_KEY'] != nil and ENV['AMAZON_SECRET_ACCESS_KEY'] != ""
      @softlayer_secret_access_key.text = ENV['AMAZON_SECRET_ACCESS_KEY']
    end

    amazon_env.connect(SEL_CHANGED) {
      google_env.text = amazon_env.text
      openstack_env.text = amazon_env.text
      azure_env.text = amazon_env.text
      rack_env.text = amazon_env.text
      softlayer_env.text = amazon_env.text
      servers_env = amazon_env.text
      @new_env = amazon_env.text
      @ec2_platform = "amazon"
    }

    google_env.connect(SEL_CHANGED) {
      amazon_env.text = google_env.text
      google_env.text = google_env.text
      openstack_env.text = google_env.text
      rack_env.text = google_env.text
      softlayer_env.text = google_env.text
      servers_env = google_env.text
      @new_env = google_env.text
      @ec2_platform = "google"
    }

    openstack_env.connect(SEL_CHANGED) {
      amazon_env.text = openstack_env.text
      google_env.text = openstack_env.text
      azure_env.text = openstack_env.text
      rack_env.text = openstack_env.text
      softlayer_env.text = openstack_env.text
      servers_env = openstack_env.text
      @new_env = openstack_env.text
      @ec2_platform = "openstack"
    }

    azure_env.connect(SEL_CHANGED) {
      amazon_env.text = azure_env.text
      google_env.text = azure_env.text
      openstack_env.text = azure_env.text
      rack_env.text = azure_env.text
      softlayer_env.text = azure_env.text
      servers_env = azure_env.text
      @new_env = azure_env.text
      @ec2_platform = "azure"
    }

    rack_env.connect(SEL_CHANGED) {
      amazon_env.text = rack_env.text
      google_env.text = rack_env.text
      azure_env.text = rack_env.text
      openstack_env.text = rack_env.text
      softlayer_env.text = rack_env.text
      servers_env = rack_env.text
      @new_env = rack_env.text
      @ec2_platform = "openstack_rackspace"
    }

    softlayer_env.connect(SEL_CHANGED) {
      amazon_env.text = softlayer_env.text
      google_env.text = softlayer_env.text
      azure_env.text = softlayer_env.text
      rack_env.text = softlayer_env.text
      openstack_env.text = softlayer_env.text
      servers_env = softlayer_env.text
      @new_env = softlayer_env.text
      @ec2_platform = "softlayer"
    }

    servers_env.connect(SEL_CHANGED) {
      amazon_env.text = servers_env.text
      google_env.text = servers_env.text
      azure_env.text = servers_env.text
      rack_env.text = servers_env.text
      softlayer_env.text = servers_env.text
      openstack_env.text = servers_env.text
      @new_env = servers_env.text
      @ec2_platform = "servers"
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
      Dir.mkdir(d+"/launch")
      save_env
      if  @ec2_platform.start_with?("openstack")
        File.new( d+"/image_cache.txt", "w")
        File.new( d+"/image_cache_self.txt", "w")
      end
      @created = true
      @ec2_main.imageCache.set_status("empty")

    rescue Exception => error
      puts error.message
      FXMessageBox.warning(self,MBOX_OK,"Error",error.message)
    end
  end

  def saved
    @created
  end

  def created
    @created
  end

  def success
    @created
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
      settings.put('SSL_CERT_FILE',"ca-bundle.crt")
    elsif @ec2_platform == "azure"
      if @azure_access_key.text != nil
        settings.put("AMAZON_ACCESS_KEY_ID",@azure_access_key.text)
      end
      if @azure_subscription_id.text != nil
        settings.put("AMAZON_ACCOUNT_ID",@azure_subscription_id.text)
      end
      if @azure_url.text != nil
        settings.put("EC2_URL",@azure_url.text)
      end
      settings.put('SSL_CERT_FILE',"ca-bundle.crt")
    elsif @ec2_platform == "openstack_rackspace"
      if @rack_access_key.text != nil
        settings.put("AMAZON_ACCESS_KEY_ID",@rack_access_key.text)
      end
      if @rack_secret_access_key.text != nil
        settings.put("AMAZON_SECRET_ACCESS_KEY",@rack_secret_access_key.text)
      end
      if @rack_url.text != nil
        settings.put("EC2_URL",@rack_url.text)
      end
      settings.put('SSL_CERT_FILE',"ca-bundle.crt")
    elsif @ec2_platform == "softlayer"
      if @softlayer_access_key.text != nil
        settings.put("AMAZON_ACCESS_KEY_ID",@softlayer_access_key.text)
      end
      if @softlayer_secret_access_key.text != nil
        settings.put("AMAZON_SECRET_ACCESS_KEY",@softlayer_secret_access_key.text)
      end
      settings.put('SSL_CERT_FILE',"ca-bundle.crt")
    elsif @ec2_platform == "google"
      if @google_client_email.text != nil
        settings.put("AMAZON_ACCESS_KEY_ID",@google_client_email.text)
      end
      if @google_key_location.text != nil
        settings.put("AMAZON_SECRET_ACCESS_KEY",@google_key_location.text)
      end
      if @google_project.text != nil
        settings.put("EC2_URL",@google_project.text)
      end
      if @google_zone.text != nil
        settings.put("AVAILABILITY_ZONE",@google_zone.text)
      end
      settings.put('SSL_CERT_FILE',"ca-bundle.crt")
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
      settings.put('AMAZON_NICKNAME_TAG',"Name")
      settings.put('SSL_CERT_FILE',"ca-bundle.crt")
    end
    settings.put('VAGRANT_REPOSITORY',"#{ENV['EC2DREAM_HOME']}/vagrant")
    settings.save
  end

end
