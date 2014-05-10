class EC2_Server

#
#  kitchen server  methods
#

 def kit_load(instance,driver,provisioner,last_action)
    puts "server.kit_load #{instance},#{driver},#{provisioner},#{last_action}"
    @type = "kit"
    @frame1.hide()
    @frame3.hide()
    @frame4.hide()
    @frame6.hide()
    @frame5.hide()
    @frame7.show()
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