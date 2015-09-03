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

   # def textBox(label, frame)
   #   FXLabel.new(frame, label )
   #   pushback = FXTextField.new(frame, 60, nil, 0, :opts => FRAME_SUNKEN)
   #   FXLabel.new(frame, "" )
   #   return pushback
   # end

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

    #@amazon_access_key = textBox("Amazon Access Key",frame1)
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
    #google_env = textBox("Environment Name",frame8)
    google_env_label = FXLabel.new(frame8, "Environment Name" )
    google_env_label.tipText = "A unique name to identified this environment in EC2Dream"
    google_env = FXTextField.new(frame8, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame8, "" )
    #@google_client_email = textBox("Google Client Email",frame8)
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
    # eucalyptus
    #
    #@eucatab = FXTabItem.new(@tabbook, "&Eucalyptus", nil)
    #@eucaframe = FXHorizontalFrame.new(@tabbook)
    #frame2 = FXMatrix.new(@eucaframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    #euca_env = textBox("Environment Name",frame2)
    #FXLabel.new(frame2, "Eucalyptus certificate zipfile" )
    #@eucazipfile = FXTextField.new(frame2, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    #open = FXButton.new(frame2, "", nil, self, ID_ACCEPT, BUTTON_TOOLBAR|LAYOUT_LEFT)
    #open.icon = @magnifier
    #open.connect(SEL_COMMAND) {
    #  eucazip = FXFileDialog.getOpenFilename(self, "Locate your eucalyptus certificate zipfile", "<eucalyptus certificate zipfile>", "*.zip")
    #  if eucazip
    #    @eucazipfile.text = eucazip
    #  end
    #}

    #
    # openstack
    #
    @openstacktab = FXTabItem.new(@tabbook, "&OpenStack", nil)
    @openstacktab.tipText = "Openstack Cloud"
    @openstackframe = FXHorizontalFrame.new(@tabbook )
    frame3 = FXMatrix.new(@openstackframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    #openstack_env = textBox("Environment Name",frame3)
    openstack_env_label = FXLabel.new(frame3, "Environment Name" )
    openstack_env_label.tipText = "A unique name to identified this environment in EC2Dream"
    openstack_env = FXTextField.new(frame3, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame3, "" )
    #@openstack_access_key = textBox("User Name",frame3)
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
    @openstack_tenant_label = FXLabel.new(frame3, "Tenant ID" )
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
    # openstack_hp
    #
    @hptab = FXTabItem.new(@tabbook, "&HP OpenStack", nil)
    @hptab.tipText = "HP Helion Public Cloud"
    @hpframe = FXHorizontalFrame.new(@tabbook )
    frame4 = FXMatrix.new(@hpframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    #hp_env = textBox("Environment Name",frame4)
    hp_env_label = FXLabel.new(frame4, "Environment Name" )
    hp_env_label.tipText = "A unique name to identified this environment in EC2Dream"
    hp_env = FXTextField.new(frame4, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame4, "" )
    #@hp_access_key = textBox("HP User Name",frame4)
    @hp_access_label = FXLabel.new(frame4, "HP User Name" )
    @hp_access_label.tipText = "Your HP Openstack user name."
    @hp_access = FXTextField.new(frame4, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame4, "" )
    @hp_secret_access_key_label = FXLabel.new(frame4, "HP Password" )
    @hp_secret_access_key_label.tipText = "Your HP Openstack password."
    @hp_secret_access_key = FXTextField.new(frame4, 60, nil, 0, :opts => TEXTFIELD_PASSWD|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame4, "" )
    @hp_url_label = FXLabel.new(frame4, "HP URL" )
    @hp_url_label.tipText = "HP Cloud Identity Service API Endpoint"
    @hp_url = FXTextField.new(frame4, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame4, "" )
    @hp_tenant_label = FXLabel.new(frame4, "HP Tenant ID" )
    @hp_tenant_label.tipText = "The initial implementation of OpenStack Compute had its own authentication system and used the term project.\nWhen authentication moved into the OpenStack Identity (keystone) project, it used the term tenant to refer to a group of users.\nBecause of this legacy, some of the OpenStack tools refer to projects and some refer to tenants."
    @hp_tenant = FXTextField.new(frame4, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame4, "" )
    @hp_avl_zone_label = FXLabel.new(frame4, "HP Avl Zone" )
    @hp_avl_zone_label.tipText = "The region and availability zone you wish to access.\nCreate multiple environments for multiple availability zones."
    @hp_avl_zone = FXTextField.new(frame4, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @hp_avl_zone_button = FXButton.new(frame4, "", :opts => BUTTON_TOOLBAR)
    @hp_avl_zone_button.icon = @magnifier
    @hp_avl_zone_button.tipText = "Select Availability Zone"
    @hp_avl_zone_button.connect(SEL_COMMAND) do
      @dialog = EC2_AvailZoneDialog.new(@ec2_main,"openstack_hp")
      @dialog.execute
      it = @dialog.selected
      if it != nil and it != ""
        @hp_avl_zone.text = it
      end
    end
    if ENV['AMAZON_ACCESS_KEY_ID'] != nil and ENV['AMAZON_ACCESS_KEY_ID'] != ""
      @hp_access_key.text = ENV['AMAZON_ACCESS_KEY_ID']
    end
    if ENV['AMAZON_SECRET_ACCESS_KEY'] != nil and ENV['AMAZON_SECRET_ACCESS_KEY'] != ""
      @hp_secret_access_key.text = ENV['AMAZON_SECRET_ACCESS_KEY']
    end
    #if ENV['AMAZON_SECRET_ACCESS_KEY'] != nil and ENV['AMAZON_SECRET_ACCESS_KEY'] != ""
    #     @openstack_secret_access_key.text = ENV['AMAZON_SECRET_ACCESS_KEY']
    #end
    #if ENV['EC2_URL'] != nil and ENV['EC2_URL'] != ""
    #    @hp_url.text =  ENV['EC2_URL']
    #else
    @hp_url.text = 'https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/'
    #end
    if ENV['AMAZON_ACCOUNT_ID'] != nil and ENV['AMAZON_ACCOUNT_ID'] != ""
      @hp_tenant.text = ENV['AMAZON_ACCOUNT_ID']
    end
    if ENV['AVAILABILITY_ZONE'] != nil and ENV['AVAILABILITY_ZONE'] != ""
      @hp_avl_zone.text = ENV['AVAILABILITY_ZONE']
    else
      @hp_avl_zone.text = "az-1.region-a.geo-1"
    end
    # NOTE: if strings don't work for avail zones try symbols like :az1
    #
    # openstack_rackspace
    #
    @racktab = FXTabItem.new(@tabbook, "&Rackspace", nil)
    @racktab.tipText = "Rackspace Public Cloud"
    @rackframe = FXHorizontalFrame.new(@tabbook )
    frame5 = FXMatrix.new(@rackframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    #rack_env = textBox("Environment Name",frame5)
    rack_env_label = FXLabel.new(frame5, "Environment Name" )
    rack_env_label.tipText = "A unique name to identified this environment in EC2Dream"
    rack_env = FXTextField.new(frame5, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame5, "" )
    #@rack_access_key = textBox("Rackspace User Name",frame5)
    @rack_access_key_label = FXLabel.new(frame5, "Rackspace User Name" )
    @rack_access_key_label.tipText = "Your HP Openstack user name."
    @rack_access_key = FXTextField.new(frame5, 60, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame5, "" )
    @rack_secret_access_key_label = FXLabel.new(frame5, "Rackspace API Key" )
    @rack_secret_access_key_label.tipText = "Your HP Openstack API Key"
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
    # cloudstack
    #
    #@cloudstacktab = FXTabItem.new(@tabbook, "&CloudStack", nil)
    #@cloudstackframe = FXHorizontalFrame.new(@tabbook )
    #frame6 = FXMatrix.new(@cloudstackframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    #cloudstack_env = textBox("Environment Name",frame6)
    #@cloudstack_access_key = textBox("CloudStack API Key",frame6)
    #FXLabel.new(frame6, "CloudStack Secret Key" )
    #@cloudstack_secret_access_key = FXTextField.new(frame6, 60, nil, 0, :opts => TEXTFIELD_PASSWD|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    #FXLabel.new(frame6, "" )
    #FXLabel.new(frame6, "CloudStack URL" )
    #@cloudstack_url = FXTextField.new(frame6, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    #if ENV['AMAZON_ACCESS_KEY_ID'] != nil and ENV['AMAZON_ACCESS_KEY_ID'] != ""
    #  @cloudstack_access_key.text = ENV['AMAZON_ACCESS_KEY_ID']
    #end
    #if ENV['AMAZON_SECRET_ACCESS_KEY'] != nil and ENV['AMAZON_SECRET_ACCESS_KEY'] != ""
    #  @cloudstack_secret_access_key.text = ENV['AMAZON_SECRET_ACCESS_KEY']
    #end
    ##if ENV['AMAZON_SECRET_ACCESS_KEY'] != nil and ENV['AMAZON_SECRET_ACCESS_KEY'] != ""
    ##     @openstack_secret_access_key.text = ENV['AMAZON_SECRET_ACCESS_KEY']
    ##end
    ##if ENV['EC2_URL'] != nil and ENV['EC2_URL'] != ""
    ##    @cloudstack_url.text =  ENV['EC2_URL']
    ##else
    ## @cloudstack_url.text = "http://cloud-bridge-hostname:8090/bridge"  # cloudstack 4.0
    #@cloudstack_url.text = "http://localhost:7080/awsapi"                # cloudstack 4.1
    ##end
    #FXLabel.new(frame6, "")
    #FXLabel.new(frame6, "")
    #FXLabel.new(frame6, "")
    #FXLabel.new(frame6, "")
    #FXLabel.new(frame6, "")
    #FXLabel.new(frame6, "NOTE: Cloudstack 4.1 is supported by default. To change the version edit")
    #FXLabel.new(frame6, "")
    #FXLabel.new(frame6, "")
    #FXLabel.new(frame6, "the file cloudstack.rb in the lib folder to set the correct AWS API Version")
    #FXLabel.new(frame6, "")
    #FXLabel.new(frame6, "")
    #FXLabel.new(frame6, "")

    #
    # cloudfoundry
    #
    #@cloudfoundrytab = FXTabItem.new(@tabbook, "&CloudFoundry", nil)
    #@cloudfoundryframe = FXHorizontalFrame.new(@tabbook )
    #frame7 = FXMatrix.new(@cloudfoundryframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    #cloudfoundry_env = textBox("Environment Name",frame7)
    #@cloudfoundry_access_key = textBox("CloudFoundry User Name",frame7)
    #FXLabel.new(frame7, "CloudFoundry Password" )
    #@cloudfoundry_secret_access_key = FXTextField.new(frame7, 60, nil, 0, :opts => TEXTFIELD_PASSWD|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    #FXLabel.new(frame7, "" )
    #FXLabel.new(frame7, "CloudFoundry URL" )
    #@cloudfoundry_url = FXTextField.new(frame7, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    #@cloudfoundry_url_button = FXButton.new(frame7, "", :opts => BUTTON_TOOLBAR)
    #@cloudfoundry_url_button.icon = @magnifier
    #@cloudfoundry_url_button.tipText = "Select URL"
    #@cloudfoundry_url_button.connect(SEL_COMMAND) do
    #  @dialog = EC2_RegionsDialog.new(@ec2_main,"","cloudfoundry")
    #  @dialog.execute
    #  it = @dialog.selected
    #  if it != nil and it != ""
    #    @cloudfoundry_url.text = it
    #  end
    #end
    #if ENV['AMAZON_ACCESS_KEY_ID'] != nil and ENV['AMAZON_ACCESS_KEY_ID'] != ""
    #  @cloudfoundry_access_key.text = ENV['AMAZON_ACCESS_KEY_ID']
    #end
    #if ENV['AMAZON_SECRET_ACCESS_KEY'] != nil and ENV['AMAZON_SECRET_ACCESS_KEY'] != ""
    #  @cloudfoundry_secret_access_key.text = ENV['AMAZON_SECRET_ACCESS_KEY']
    #end
    #@cloudfoundry_url.text = "http://api.cloudfoundry.com/"


    amazon_env.connect(SEL_CHANGED) {
      google_env.text = amazon_env.text
      openstack_env.text = amazon_env.text
      hp_env.text = amazon_env.text
      rack_env.text = amazon_env.text
      servers_env = amazon_env.text
      @new_env = amazon_env.text
      @ec2_platform = "amazon"
    }

    google_env.connect(SEL_CHANGED) {
      amazon_env.text = google_env.text
      google_env.text = google_env.text
      openstack_env.text = google_env.text
      rack_env.text = google_env.text
      servers_env = google_env.text
      @new_env = google_env.text
      @ec2_platform = "google"
    }

   # euca_env.connect(SEL_CHANGED) {
   #   amazon_env.text = euca_env.text
   #   google_env.text = euca_env.text
   #   openstack_env.text = euca_env.text
   #   hp_env.text = euca_env.text
   #   rack_env.text = euca_env.text
   #   cloudstack_env.text = euca_env.text
   #   cloudfoundry_env = euca_env.text
   #   servers_env = euca_env.text
   #   @new_env = euca_env.text
   #   @ec2_platform = "eucalyptus"
   # }

    openstack_env.connect(SEL_CHANGED) {
      amazon_env.text = openstack_env.text
      google_env.text = openstack_env.text
      hp_env.text = openstack_env.text
      rack_env.text = openstack_env.text
      servers_env = openstack_env.text
      @new_env = openstack_env.text
      @ec2_platform = "openstack"
    }

    hp_env.connect(SEL_CHANGED) {
      amazon_env.text = hp_env.text
      google_env.text = hp_env.text
      openstack_env.text = hp_env.text
      rack_env.text = hp_env.text
      servers_env = hp_env.text
      @new_env = hp_env.text
      @ec2_platform = "openstack_hp"
    }

    rack_env.connect(SEL_CHANGED) {
      amazon_env.text = rack_env.text
      google_env.text = rack_env.text
      hp_env.text = rack_env.text
      openstack_env.text = rack_env.text
      servers_env = rack_env.text
      @new_env = rack_env.text
      @ec2_platform = "openstack_rackspace"
    }

    #cloudstack_env.connect(SEL_CHANGED) {
    #  amazon_env.text = cloudstack_env.text
    #  google_env.text = cloudstack_env.text
    #  euca_env.text = cloudstack_env.text
    #  hp_env.text = cloudstack_env.text
    #  rack_env.text = cloudstack_env.text
    #  openstack_env.text = cloudstack_env.text
    #  cloudfoundry_env = cloudstack_env.text
    #  servers_env = cloudstack_env.text
    #  @new_env = cloudstack_env.text
    #  @ec2_platform = "cloudstack"
    #}

    #cloudfoundry_env.connect(SEL_CHANGED) {
    #  amazon_env.text = cloudfoundry_env.text
    #  google_env.text = cloudfoundry_env.text
    #  euca_env.text = cloudfoundry_env.text
    #  hp_env.text = cloudfoundry_env.text
    #  rack_env.text = cloudfoundry_env.text
    #  openstack_env.text = cloudfoundry_env.text
    #  servers_env = cloudfoundry_env.text
    #  @new_env = cloudfoundry_env.text
    #  @ec2_platform = "cloudfoundry"
    #}

    servers_env.connect(SEL_CHANGED) {
      amazon_env.text = servers_env.text
      google_env.text = servers_env.text
      hp_env.text = servers_env.text
      rack_env.text = servers_env.text
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
      #if @eucazipfile.text != ""
      #  unzip(@eucazipfile.text,d)
      #  eucarcpath = d+"/euca/eucarc"
      #  raise 'Not a valid Eucalyptus zipfile' unless File.exists?(eucarcpath)
      #  eucarc = File.open(eucarcpath, 'r')
      #  eucarc.read.each_line do |configline|
      #    if configline =~ /EC2_ACCESS_KEY=\'(\w+)\'/
      #      @amazon_access_key.text = $1
      #    end
      #    if configline =~ /EC2_SECRET_KEY=\'([^\']+)\'/
      #      @amazon_secret_access_key.text = $1
      #    end
      #    if configline =~ /EC2_URL=(.+)$/
      #      @ec2_url.text = $1
      #    end
      #  end
      #  @ec2_platform = "eucalyptus"
      #  eucarc.close
      #end
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
    elsif @ec2_platform == "openstack_hp"
      if @hp_access_key.text != nil
        settings.put("AMAZON_ACCESS_KEY_ID",@hp_access_key.text)
      end
      if @hp_secret_access_key.text != nil
        settings.put("AMAZON_SECRET_ACCESS_KEY",@hp_secret_access_key.text)
      end
      if @hp_url.text != nil
        settings.put("EC2_URL",@hp_url.text)
      end
      if @hp_tenant.text != nil
        settings.put("AMAZON_ACCOUNT_ID",@hp_tenant.text)
      end
      if @hp_avl_zone.text != nil
        settings.put("AVAILABILITY_ZONE",@hp_avl_zone.text)
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
   # elsif @ec2_platform == "cloudstack"
   #   if @cloudstack_access_key.text != nil
   #     settings.put("AMAZON_ACCESS_KEY_ID",@cloudstack_access_key.text)
   #   end
   #   if @cloudstack_secret_access_key.text != nil
   #     settings.put("AMAZON_SECRET_ACCESS_KEY",@cloudstack_secret_access_key.text)
   #   end
   #   if @cloudstack_url.text != nil
   #     settings.put("EC2_URL",@cloudstack_url.text)
   #   end
   #   settings.put('SSL_CERT_FILE',"ca-bundle.crt")
   # elsif @ec2_platform == "cloudfoundry"
   #   if @cloudfoundry_access_key.text != nil
   #     settings.put("AMAZON_ACCESS_KEY_ID",@cloudfoundry_access_key.text)
   #   end
   #   if @cloudfoundry_secret_access_key.text != nil
   #     settings.put("AMAZON_SECRET_ACCESS_KEY",@cloudfoundry_secret_access_key.text)
   #   end
   #   if @cloudfoundry_url.text != nil
   #     settings.put("EC2_URL",@cloudfoundry_url.text)
   #   end
   #   settings.put('SSL_CERT_FILE',"ca-bundle.crt")
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

  #def unzip(eucazip,envpath)
  #  Dir.mkdir(envpath+"/euca")
  #  arch = Zip::ZipFile.open(eucazip)
  #  arch.each do |entry|
  #    xtrpath = File.join(envpath+"/euca/", entry.name)
  #    raise 'Eucalyptus zipfile in an unsupported format' if xtrpath =~ /euca\/.+\/.+/
  #    arch.extract(entry, xtrpath)
  #  end
  #end

end
