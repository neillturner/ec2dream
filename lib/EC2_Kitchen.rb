require 'rubygems'
require 'fox16'
require 'fox16/colors'
require 'fox16/scintilla'
require 'net/http'
require 'resolv'
require 'dialog/KIT_LogSelectDialog'
require 'common/kitchen_cmd'

class EC2_Kitchen

  def initialize(owner)
        @ec2_main = owner

	@kit_server = {}
	@kit_debug = false

	@arrow_refresh = @ec2_main.makeIcon("arrow_redo.png")
	@arrow_refresh.create
	@monitor = @ec2_main.makeIcon("monitor.png")
	@monitor.create
	@put = @ec2_main.makeIcon("application_put.png")
	@put.create
        @desktop = @ec2_main.makeIcon("windows.png")
	@desktop.create
	@disconnect = @ec2_main.makeIcon("disconnect.png")
	@disconnect.create
	@log = @ec2_main.makeIcon("script.png")
	@log.create
	@modify = @ec2_main.makeIcon("application_edit.png")
	@modify.create
	@mon = @ec2_main.makeIcon("dashboard.png")
	@mon.create
	@unmon = @ec2_main.makeIcon("dashboard_stop.png")
	@unmon.create
	@delete = @ec2_main.makeIcon("kill.png")
	@delete.create
	@start_icon = @ec2_main.makeIcon("arrow_right.png")
	@start_icon.create
	@rocket = @ec2_main.makeIcon("rocket.png")
	@rocket.create
	@arrow_in = @ec2_main.makeIcon("arrow_in.png")
	@arrow_in.create
        @edit = @ec2_main.makeIcon("accept.png")
	@edit.create
	@bug = @ec2_main.makeIcon("bug.png")
	@bug.create
	@style = @ec2_main.makeIcon("style.png")
	@style.create
	@lightbulb = @ec2_main.makeIcon("lightbulb.png")
	@lightbulb.create
	@tunnel = @ec2_main.makeIcon("tunnel.png")
	@tunnel.create



        tab6 = FXTabItem.new(@ec2_main.tabBook, " Kitchen ")
        @page1 = FXVerticalFrame.new(@ec2_main.tabBook, LAYOUT_FILL, :padding => 0)
        page1a = FXHorizontalFrame.new(@page1,LAYOUT_FILL_X, :padding => 0)
    	@server_label = FXLabel.new(page1a, "" )
	@refresh_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@refresh_button.icon = @arrow_refresh
	@refresh_button.tipText = "Server Status Refresh"
	@refresh_button.connect(SEL_COMMAND) do |sender, sel, data|
            kit_refresh
	end
	@refresh_button.connect(SEL_UPDATE) do |sender, sel, data|
	   enable_if_env_set(sender)
	end
    	@putty_button = FXButton.new(page1a," ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@putty_button.icon = @monitor
        @putty_button.tipText = " SSH "
	@putty_button.connect(SEL_COMMAND) do |sender, sel, data|
   	   kit_ssh
        end
	@putty_button.connect(SEL_UPDATE) do |sender, sel, data|
	   sender.enabled = true
	end
	@winscp_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@winscp_button.icon = @put
	@winscp_button.tipText = "  SCP  "
	@winscp_button.connect(SEL_COMMAND) do |sender, sel, data|
  	   kit_winscp
	end
	@winscp_button.connect(SEL_UPDATE) do |sender, sel, data|
	   sender.enabled = true
	end
        if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
	   @remote_desktop_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	   @remote_desktop_button.icon = @desktop
	   @remote_desktop_button.tipText = " Windows Remote Desktop "
	   @remote_desktop_button.connect(SEL_COMMAND) do |sender, sel, data|
	       kit_rdp
	   end
	   @remote_desktop_button.connect(SEL_UPDATE) do |sender, sel, data|
	       sender.enabled = true
	   end
	end
	@terminate_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@terminate_button.icon = @modify
	@terminate_button.tipText = " Edit Kitchem yml File "
	@terminate_button.connect(SEL_COMMAND) do |sender, sel, data|
            kit_edit
	end
	@terminate_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
	@log_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@log_button.icon = @log
	@log_button.tipText = " Console Output "
	@log_button.connect(SEL_COMMAND) do |sender, sel, data|
          kit_log
 	end
	@log_button.connect(SEL_UPDATE) do |sender, sel, data|
           sender.enabled = true
	end
	@mon_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@mon_button.icon = @delete
        @mon_button.tipText = " Destroy Instance "
	@mon_button.connect(SEL_COMMAND) do |sender, sel, data|
           kit_destroy
 	end
	@mon_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
	@unmon_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@unmon_button.icon = @rocket
	@unmon_button.tipText = " Create Instance "
	@unmon_button.connect(SEL_COMMAND) do |sender, sel, data|
            kit_create
 	end
	@unmon_button.connect(SEL_UPDATE) do |sender, sel, data|
	   sender.enabled = true
	end
	@start_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@start_button.icon = @arrow_in
	@start_button.tipText = " Converge Instance "
	@start_button.connect(SEL_COMMAND) do |sender, sel, data|
           kit_converge
 	end
	@start_button.connect(SEL_UPDATE) do |sender, sel, data|
	      sender.enabled = true

	end
	@stop_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
        @stop_button.icon = @edit
	@stop_button.tipText = " Verify Instance "
	@stop_button.connect(SEL_COMMAND) do |sender, sel, data|
	   kit_verify
 	end
	@stop_button.connect(SEL_UPDATE) do |sender, sel, data|
	      sender.enabled = true
	end
	@create_image_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@create_image_button.icon = @bug
	@create_image_button.tipText = " Set Kitchen Debug level logs "
	@create_image_button.connect(SEL_COMMAND) do |sender, sel, data|
          kit_debug
 	end
	@create_image_button.connect(SEL_UPDATE) do |sender, sel, data|
	   sender.enabled = true
	end
	@chef_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@chef_button.icon =  @start_icon
	@chef_button.tipText = " Kitchen test instance "
	@chef_button.connect(SEL_COMMAND) do |sender, sel, data|
	   kit_test
	end
	@chef_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
	@puppet_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@puppet_button.icon = @style
	@puppet_button.tipText = " Run Foodcritic "
	@puppet_button.connect(SEL_COMMAND) do |sender, sel, data|
	    kit_foodcritic
	end
	@puppet_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
	@graph_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@graph_button.icon = @lightbulb
	@graph_button.tipText = " Run rspec "
	@graph_button.connect(SEL_COMMAND) do |sender, sel, data|
	    kit_rspec_test
 	end
	@graph_button.connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
	@tunnel_button = FXButton.new(page1a," ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
	@tunnel_button.icon = @tunnel
        @tunnel_button.tipText = " Setup SSH Tunnel"
	@tunnel_button.connect(SEL_COMMAND) do |sender, sel, data|
	end
	@tunnel_button.connect(SEL_UPDATE) do |sender, sel, data|
           sender.enabled = false
	end

	#
	# kitchen  frame
	#
	@frame1 = FXMatrix.new(@page1, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(@frame1, "Instance" )
    @kit_server['instance'] = FXTextField.new(@frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Driver" )
    @kit_server['driver'] = FXTextField.new(@frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Provisioner" )
    @kit_server['provisioner'] = FXTextField.new(@frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Last Action" )
    @kit_server['last_action'] = FXTextField.new(@frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Test Kitchen Path" )
    @kit_server['test_kitchen_path'] = FXTextField.new(@frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    @kit_server['test_kitchen_path_button'] = FXButton.new(@frame1, " ",:opts => BUTTON_TOOLBAR)
    @kit_server['test_kitchen_path_button'].icon = @modify
    @kit_server['test_kitchen_path_button'].tipText = "  Configure Test Kitchen Path  "
    @kit_server['test_kitchen_path_button'].connect(SEL_COMMAND) do |sender, sel, data|
        dialog = KIT_PathCreateDialog.new(@ec2_main)
        dialog.execute
        if dialog.success
            @ec2_main.tabBook.setCurrent(0)
            @ec2_main.list.load("Test Kitchen")
        end
    end
    FXLabel.new(@frame1, "SSH User" )
    @kit_server['ssh_user'] = FXTextField.new(@frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Foodcritic cookbook_path" )
    @kit_server['chef_foodcritic'] = FXTextField.new(@frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @kit_server['chef_foodcritic'].connect(SEL_COMMAND) do
        @ec2_main.settings.put('CHEF_FOODCRITIC',@kit_server['chef_foodcritic'].text)
	@ec2_main.settings.save
    end
    FXLabel.new(@frame1, "path of cookbook from TEST_KITCHEN_PATH" )
    FXLabel.new(@frame1, "RSpec spec files" )
    @kit_server['chef_rspec_test'] = FXTextField.new(@frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @kit_server['chef_rspec_test'].connect(SEL_COMMAND) do
       @ec2_main.settings.put('CHEF_RSPEC_TEST',@kit_server['chef_rspec_test'].text)
       @ec2_main.settings.save
    end
    FXLabel.new(@frame1, "spec files to run  from TEST_KITCHEN_PATH" )
  end


  def enable_if_env_set(sender)
       @env = @ec2_main.environment.env
       if @env != nil and @env.length>0
       	sender.enabled = true
       else
         sender.enabled = false
       end

 end

 def kit_load(instance,driver,provisioner,last_action)
    puts "server.kit_load #{instance},#{driver},#{provisioner},#{last_action}"
    @page1.width=300
    @kit_server['instance'].text = instance
    @kit_server['driver'].text = driver
    @kit_server['provisioner'].text = provisioner
    @kit_server['last_action'].text = last_action
    @kit_server['test_kitchen_path'].text = @ec2_main.settings.get('TEST_KITCHEN_PATH')
    @kit_server['chef_foodcritic'].text = @ec2_main.settings.get('CHEF_FOODCRITIC')
    @kit_server['chef_rspec_test'].text = @ec2_main.settings.get('CHEF_RSPEC_TEST')
    @kit_server['test_kitchen_path'].text ="#{ENV['EC2DREAM_HOME']}/chef/chef-repo/site-cookbooks/mycompany_webserver" if @kit_server['test_kitchen_path'].text==nil or @kit_server['test_kitchen_path'].text==""
    @kit_server['chef_foodcritic'].text ="." if @kit_server['chef_foodcritic'].text==nil or @kit_server['chef_foodcritic'].text==""
    @kit_server['chef_rspec_test'].text ="./spec/unit/*_spec.rb" if @kit_server['chef_rspec_test'].text==nil or @kit_server['chef_rspec_test'].text==""
  end

  def kit_refresh
    data = kitchen_cmd('list',@kit_server['instance'].text)
    if data != nil and data[0] !=nil
       @kit_server['instance'].text = data[0]['Instance']
       @kit_server['driver'].text = data[0]['Driver']
       @kit_server['provisioner'].text = data[0]['Provisioner']
       @kit_server['last_action'].text = data[0]['Last-Action']
       @kit_server['test_kitchen_path'].text = @ec2_main.settings.get('TEST_KITCHEN_PATH')
       @kit_server['chef_foodcritic'].text = @ec2_main.settings.get('CHEF_FOODCRITIC')
       @kit_server['chef_rspec_test'].text = @ec2_main.settings.get('CHEF_RSPEC_TEST')
       @kit_server['test_kitchen_path'].text ="#{ENV['EC2DREAM_HOME']}/chef/chef-repo/site-cookbooks/mycompany_webserver" if @kit_server['test_kitchen_path'].text==nil or @kit_server['test_kitchen_path'].text==""
       @kit_server['chef_foodcritic'].text ="." if @kit_server['chef_foodcritic'].text==nil or @kit_server['chef_foodcritic'].text==""
       @kit_server['chef_rspec_test'].text ="./spec/unit/*_spec.rb" if @kit_server['chef_rspec_test'].text==nil or @kit_server['chef_rspec_test'].text==""
    end
  end


  def kit_ssh(utility='ssh')
        r = kitchen_cmd('config',@kit_server['instance'].text)
	username = 'root'
	username = r['username'] if r['username'] != nil and r['username'] != ""
	username = @kit_server['ssh_user'].text if @kit_server['ssh_user'].text != nil and @kit_server['ssh_user'].text != ""
	password = nil
	password = 'vagrant' if @kit_server['driver'].text == 'Vagrant'
	private_key = nil
        private_key = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY') if @kit_server['driver'].text != 'Vagrant'
	putty_key = nil
        putty_key = @ec2_main.settings.get('PUTTY_PRIVATE_KEY') if @kit_server['driver'].text != 'Vagrant'
	if r != nil
	   if utility == 'scp'
	      scp(@kit_server['instance'].text, r['hostname'], username, private_key, putty_key, password,r['port'])
	   else
              ssh(@kit_server['instance'].text, r['hostname'], username, private_key, putty_key, password,r['port'])
	   end
 	end
  end

  def kit_rdp
  end

  def kit_winscp
    kit_ssh('scp')
  end

  def kit_edit
    kitchen_cmd('edit')
  end

  def kit_create
    kitchen_cmd('create',@kit_server['instance'].text,@kit_debug)
  end

  def kit_log
     dialog = KIT_LogSelectDialog.new(@ec2_main)
     dialog.execute
  end

  def kit_destroy
    kitchen_cmd('destroy',@kit_server['instance'].text,@kit_debug)
  end

  def kit_converge
    kitchen_cmd('converge',@kit_server['instance'].text,@kit_debug)
  end

  def kit_verify
    kitchen_cmd('verify',@kit_server['instance'].text,@kit_debug)
  end

  def kit_test
    kitchen_cmd('test',@kit_server['instance'].text,@kit_debug)
  end

  def kit_debug
    if @kit_debug
       @kit_debug=false
        FXMessageBox.information($ec2_main.tabBook,MBOX_OK,"Kitchen Debug Logging","Kitchen Debug Logging set off")
    else
       @kit_debug=true
       FXMessageBox.information($ec2_main.tabBook,MBOX_OK,"Kitchen Debug Logging","Kitchen Debug Logging set on")
    end
  end

  def kit_foodcritic
     kitchen_cmd('foodcritic',@kit_server['chef_foodcritic'].text)
  end

  def kit_rspec_test
     kitchen_cmd('rspec',@kit_server['chef_rspec_test'].text)
  end

end