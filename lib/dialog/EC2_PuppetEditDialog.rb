require 'rubygems'
require 'fox16'
require 'common/error_message'

include Fox

class EC2_PuppetEditDialog < FXDialogBox

  def initialize(owner)
    #puts "PuppetEditDialog.initialize"
    @saved = false
    @ec2_main = owner
	settings = @ec2_main.settings
    parm = {}
	parm['puppet_repository'] = settings.get('PUPPET_REPOSITORY')
	parm['puppet_module_path'] = settings.get('PUPPET_MODULE_PATH')
	parm['puppet_syntax_check'] = settings.get('PUPPET_SYNTAX_CHECK')
	parm['puppet_rspec_test'] = settings.get('PUPPET_RSPEC_TEST')
    parm['puppet_apply'] = settings.get('PUPPET_APPLY')
	parm['puppet_apply_noop'] = settings.get('PUPPET_APPLY_NOOP')
	parm['puppet_extra_options'] = settings.get('PUPPET_EXTRA_OPTIONS')
	parm['puppet_delete_repo'] = settings.get('PUPPET_DELETE_REPO')
	parm['puppet_sudo_password'] = settings.get('PUPPET_SUDO_PASSWORD')
	parm['puppet_upgrade_packages'] = settings.get('PUPPET_UPGRADE_PACKAGES')	
	@magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    super(@ec2_main, "Configure Puppet", :opts => DECOR_ALL, :width => 800, :height => 350)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Puppet Repository" )    
    puppet_repository = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
 	puppet_repository_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	puppet_repository_button.icon = @magnifier
	puppet_repository_button.tipText = "Browse..."
	puppet_repository_button.connect(SEL_COMMAND) do
	   dialog = FXDirDialog.new(frame1, "Select Puppet Repository Directory")
       dialog.directory = "#{ENV['EC2DREAM_HOME']}/puppet/puppet-repo"
	   if dialog.execute != 0
	      puppet_repository.text = dialog.directory
       end
	end	
    FXLabel.new(frame1, "Puppet Module Path" )
    puppet_module_path = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "(separated by colons)" )
    FXLabel.new(frame1, "Syntax Check Module" )
    puppet_syntax_check = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "e.g. modules-mycompany/mycompany-webserver" )    
    FXLabel.new(frame1, "Rspec Test Module" )
    puppet_rspec_test = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "e.g. modules-mycompany/mycompany-webserver" )
    FXLabel.new(frame1, "Run Puppet Apply" )
    puppet_apply = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    puppet_apply.numVisible = 2      
    puppet_apply.appendItem("true")	
    puppet_apply.appendItem("false")
    puppet_apply.setCurrentItem(0) 	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Run Puppet Apply --noop" )
    puppet_apply_noop = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    puppet_apply_noop.numVisible = 2      
    puppet_apply_noop.appendItem("true")	
    puppet_apply_noop.appendItem("false")
    puppet_apply_noop.setCurrentItem(1) 	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Extra Puppet apply options" )
    puppet_extra_options = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Delete Puppet Repo" )
    puppet_delete_repo = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    puppet_delete_repo.numVisible = 2      
    puppet_delete_repo.appendItem("true")	
    puppet_delete_repo.appendItem("false")
    puppet_delete_repo.setCurrentItem(1) 	
    FXLabel.new(frame1, "" )	
    FXLabel.new(frame1, "Sudo Password" )
    puppet_sudo_password = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Upgrade Packages" )
    puppet_upgrade_packages = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    puppet_upgrade_packages.numVisible = 2      
    puppet_upgrade_packages.appendItem("true")	
    puppet_upgrade_packages.appendItem("false")
    puppet_upgrade_packages.setCurrentItem(0) 	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )       
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
	    r = {}
        r['puppet_repository']=puppet_repository.text
        r['puppet_module_path']=puppet_module_path.text
        r['puppet_syntax_check']=puppet_syntax_check.text
        r['puppet_rspec_test']=puppet_rspec_test.text
		r['puppet_apply']="false"	
        if puppet_apply.itemCurrent?(0)
	      r['puppet_apply']="true"
        end		
		r['puppet_apply_noop']="false"	
        if puppet_apply_noop.itemCurrent?(0)
	      r['puppet_apply_noop']="true"
        end		
        r['puppet_extra_options']=puppet_extra_options.text
        r['puppet_delete_repo']="false"	
        if puppet_delete_repo.itemCurrent?(0)
	      r['puppet_delete_repo']="true"
        end			
        r['puppet_sudo_password']=puppet_sudo_password.text
        r['puppet_upgrade_packages']="false"	
        if puppet_upgrade_packages.itemCurrent?(0)
	      r['puppet_upgrade_packages']="true"
        end	
	    settings.put('PUPPET_REPOSITORY',r['puppet_repository'])
	    settings.put('PUPPET_MODULE_PATH',r['puppet_module_path'])
	    settings.put('PUPPET_SYNTAX_CHECK',r['puppet_syntax_check'])
	    settings.put('PUPPET_RSPEC_TEST',r['puppet_rspec_test'])
        settings.put('PUPPET_APPLY',r['puppet_apply'])
		settings.put('PUPPET_APPLY_NOOP',r['puppet_apply_noop'])
		settings.put('PUPPET_EXTRA_OPTIONS',r['puppet_extra_options'])
		settings.put('PUPPET_DELETE_REPO',r['puppet_delete_repo'])
		settings.put('PUPPET_SUDO_PASSWORD',r['puppet_sudo_password'])
		settings.put('PUPPET_UPGRADE_PACKAGES',r['puppet_upgrade_packages'])
        settings.save		
        @saved = true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    puppet_repository.text = parm['puppet_repository'] if parm['puppet_repository'] != nil 
    puppet_module_path.text = parm['puppet_module_path'] if parm['puppet_module_path'] != nil
    puppet_syntax_check.text = parm['puppet_syntax_check'] if parm['puppet_syntax_check'] != nil
    puppet_rspec_test.text = parm['puppet_rspec_test'] if parm['puppet_rspec_test'] != nil
	if parm['puppet_apply'] != nil
	   puppet_apply.setCurrentItem(0) if parm['puppet_apply'] == "true"
	   puppet_apply.setCurrentItem(1) if parm['puppet_apply'] == "false"
	end
	if parm['puppet_apply_noop'] != nil
	   puppet_apply_noop.setCurrentItem(0) if parm['puppet_apply_noop'] == "true"
	   puppet_apply_noop.setCurrentItem(1) if parm['puppet_apply_noop'] == "false"
	end
    puppet_extra_options.text = parm['puppet_extra_options'] if parm['puppet_extra_options'] != nil
	if parm['puppet_delete_repo'] != nil
	   puppet_delete_repo.setCurrentItem(0) if parm['puppet_delete_repo'] == "true"
	   puppet_delete_repo.setCurrentItem(1) if parm['puppet_delete_repo'] == "false"
	end
	puppet_sudo_password.text = parm['puppet_sudo_password'] if parm['puppet_sudo_password'] != nil
	if parm['puppet_upgrade_packages'] != nil
	   puppet_upgrade_packages.setCurrentItem(0) if parm['puppet_upgrade_packages'] == "true"
	   puppet_upgrade_packages.setCurrentItem(1) if parm['puppet_upgrade_packages'] == "false"
	end
  end 
  
  def saved
    @saved
  end

  def success
     @saved
  end
  
end
