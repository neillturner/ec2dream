require 'rubygems'
require 'fox16'
require 'fox16/colors'
require 'fox16/scintilla'
require 'net/http'
require 'resolv'
require 'dialog/KIT_LogSelectDialog'
require 'dialog/KIT_PathCreateDialog'
require 'common/kitchen_cmd'
require 'common/ssh'
require 'common/error_message'

class EC2_Kitchen

  def initialize(owner)
    puts "EC2_Kitchen.initialize"
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
    @script_edit = @ec2_main.makeIcon("script_edit.png")
    @script_edit.create
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
    @bookshelf = @ec2_main.makeIcon("bookshelf.png")
    @bookshelf.create
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
    if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("mingw") != nil
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
    @terminate_button.icon = @script_edit
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
    @mon_button.icon = @disconnect
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
    @puppet_button.tipText = " Run Foodcritic/puppet-lint "
    @puppet_button.connect(SEL_COMMAND) do |sender, sel, data|
      kit_foodcritic
    end
    @puppet_button.connect(SEL_UPDATE) do |sender, sel, data|
      sender.enabled = true
    end
    @check = @ec2_main.makeIcon("spellcheck.png")
    @check.create
    @parser_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @parser_button.icon = @check
    @parser_button.tipText = " Run puppet parser validate "
    @parser_button.connect(SEL_COMMAND) do |sender, sel, data|
      kit_puppet_parser
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
    @bookshelf_button = FXButton.new(page1a, " ",:opts => BUTTON_NORMAL|LAYOUT_LEFT)
    @bookshelf_button.icon = @bookshelf
    @bookshelf_button.tipText = " Run berks --debug or librarian-puppet install --verbose "
    @bookshelf_button.connect(SEL_COMMAND) do |sender, sel, data|
      p = @kit_server['provisioner'].text
      if p[0..5]=="Puppet"
        kit_librarian_puppet
      else
        kit_berks
      end
    end
    @bookshelf_button.connect(SEL_UPDATE) do |sender, sel, data|
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
    FXLabel.new(@frame1, "Verifer" )
    @kit_server['verifier'] = FXTextField.new(@frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    FXLabel.new(@frame1, "" )
    FXLabel.new(@frame1, "Transport" )
    @kit_server['transport'] = FXTextField.new(@frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
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
    FXLabel.new(@frame1, "SSH Password" )
    @kit_server['ssh_password'] = FXTextField.new(@frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(@frame1, "" )
    @kit_server['chef_foodcritic_label'] = FXLabel.new(@frame1, "Foodcritic cookbook_path" )
    @kit_server['chef_foodcritic'] = FXTextField.new(@frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    @kit_server['chef_foodcritic'].connect(SEL_COMMAND) do
      @ec2_main.settings.put('CHEF_FOODCRITIC',@kit_server['chef_foodcritic'].text)
      @ec2_main.settings.save
    end
    @kit_server['chef_foodcritic_comment'] = FXLabel.new(@frame1, "path of cookbook from TEST_KITCHEN_PATH" )
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

  def kit_load(instance,driver,provisioner,last_action,verifier=nil,transport=nil)
    puts "EC2_kitchen.kit_load #{instance},#{driver},#{provisioner},#{last_action},#{verifier},#{transport}"
    @page1.width=300
    @kit_server['instance'].text = instance
    @kit_server['driver'].text = driver
    @kit_server['provisioner'].text = provisioner
    @kit_server['verifier'].text = verifier if verifier != nil
    @kit_server['transport'].text = transport if transport != nil
    @kit_server['last_action'].text = last_action
    @kit_server['test_kitchen_path'].text = @ec2_main.settings.get('TEST_KITCHEN_PATH')
    @kit_server['ssh_user'].text = @ec2_main.settings.get('EC2_SSH_USER')
    @kit_server['ssh_password'].text = ""
    @kit_server['chef_foodcritic'].text = @ec2_main.settings.get('CHEF_FOODCRITIC')
    @kit_server['chef_rspec_test'].text = @ec2_main.settings.get('CHEF_RSPEC_TEST')
    @kit_server['test_kitchen_path'].text ="#{ENV['EC2DREAM_HOME']}/chef/chef-repo/site-cookbooks/mycompany_webserver" if @kit_server['test_kitchen_path'].text==nil or @kit_server['test_kitchen_path'].text==""
    @kit_server['chef_foodcritic'].text ="." if @kit_server['chef_foodcritic'].text==nil or @kit_server['chef_foodcritic'].text==""
    @kit_server['chef_rspec_test'].text ="./spec/unit/*_spec.rb" if @kit_server['chef_rspec_test'].text==nil or @kit_server['chef_rspec_test'].text==""
    if @kit_server['provisioner'].text == "PuppetApply"
      @kit_server['chef_foodcritic_label'].text = "puppet-lint/parser parms"
      @kit_server['chef_foodcritic_comment'].text = ""
    else
      @kit_server['chef_foodcritic_label'].text = "Foodcritic cookbook_path"
      @kit_server['chef_foodcritic_comment'].text = "path of cookbook from TEST_KITCHEN_PATH"
    end
  end

  def kit_refresh
    data = kitchen_cmd('list',@kit_server['instance'].text)
    if data != nil and data[0] !=nil
      @kit_server['instance'].text = data[0]['Instance']
      @kit_server['driver'].text = data[0]['Driver']
      @kit_server['provisioner'].text = data[0]['Provisioner']
      @kit_server['verifier'].text = data[0]['Verifier'] if data[0]['Verifier'] != nil
      @kit_server['transport'].text = data[0]['Transport'] if data[0]['Transport'] != nil
      @kit_server['last_action'].text = data[0]['Last-Action']
      @kit_server['test_kitchen_path'].text = @ec2_main.settings.get('TEST_KITCHEN_PATH')
      @kit_server['ssh_user'].text = @ec2_main.settings.get('EC2_SSH_USER')
      @kit_server['chef_foodcritic'].text = @ec2_main.settings.get('CHEF_FOODCRITIC')
      @kit_server['chef_rspec_test'].text = @ec2_main.settings.get('CHEF_RSPEC_TEST')
      @kit_server['test_kitchen_path'].text ="#{ENV['EC2DREAM_HOME']}/chef/chef-repo/site-cookbooks/mycompany_webserver" if @kit_server['test_kitchen_path'].text==nil or @kit_server['test_kitchen_path'].text==""
      @kit_server['chef_foodcritic'].text ="." if @kit_server['chef_foodcritic'].text==nil or @kit_server['chef_foodcritic'].text==""
      @kit_server['chef_rspec_test'].text ="./spec/unit/*_spec.rb" if @kit_server['chef_rspec_test'].text==nil or @kit_server['chef_rspec_test'].text==""
      if @kit_server['provisioner'].text == "PuppetApply"
        @kit_server['chef_foodcritic_label'].text = "puppet-lint/parser parms"
        @kit_server['chef_foodcritic_comment'].text = ""
      else
        @kit_server['chef_foodcritic_label'].text = "Foodcritic cookbook_path"
        @kit_server['chef_foodcritic_comment'].text = "path of cookbook from TEST_KITCHEN_PATH"
      end
    else
      error_message("Kitchen Instance undefined","Kitchen Instance #{@kit_server['instance'].text} not defined in .kitchem.yaml file")
    end
  end


  def kit_ssh(utility='ssh')
    puts "EC2_Kitchen.kit_ssh"
    r = kitchen_cmd('config',@kit_server['instance'].text)
    username = 'root'
    username = r['username'] if !r.empty? and r['username'] != nil and r['username'] != ""
    username = @kit_server['ssh_user'].text if @kit_server['ssh_user'].text != nil and @kit_server['ssh_user'].text != ""
    password = nil
    password = 'vagrant' if @kit_server['driver'].text == 'Vagrant'
    password = @kit_server['ssh_password'].text if @kit_server['ssh_password'].text != nil and @kit_server['ssh_password'].text != ""

    private_key = nil
    private_key = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY') if password == nil
    putty_key = nil
    putty_key = @ec2_main.settings.get('PUTTY_PRIVATE_KEY') if password == nil
    if !r.empty?
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

  def kit_berks
    kitchen_cmd('berks --debug')
  end

  def kit_librarian_puppet
    kitchen_cmd('librarian-puppet install --verbose')
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
    if @kit_server['provisioner'].text == "PuppetApply"
      kitchen_cmd('puppet-lint',@kit_server['chef_foodcritic'].text)
    else
      kitchen_cmd('foodcritic',@kit_server['chef_foodcritic'].text)
    end
  end

  def kit_puppet_parser
    if @kit_server['provisioner'].text == "PuppetApply"
      kitchen_cmd('puppet parser validate',@kit_server['chef_foodcritic'].text)
    end
  end

  def kit_rspec_test
    if @kit_server['provisioner'].text == "PuppetApply"
      kitchen_cmd('rspec-puppet',@kit_server['chef_rspec_test'].text)
    else
      kitchen_cmd('rspec',@kit_server['chef_rspec_test'].text)
    end
  end
end
