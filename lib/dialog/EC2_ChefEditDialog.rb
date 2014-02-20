require 'rubygems'
require 'fox16'
require 'common/error_message'

include Fox

class EC2_ChefEditDialog < FXDialogBox

  def initialize(owner)
    #puts "ChefEditDialog.initialize"
    @saved = false
    @ec2_main = owner
	settings = @ec2_main.settings
	parm = {}
	parm['chef_repository'] = settings.get('CHEF_REPOSITORY')
	parm['chef_foodcritic'] = settings.get('CHEF_FOODCRITIC')
	parm['chef_rspec_test'] = settings.get('CHEF_RSPEC_TEST')
    parm['chef_apply'] = settings.get('CHEF_APPLY')
	parm['chef_why_run'] = settings.get('CHEF_WHY_RUN')
	parm['chef_extra_options'] = settings.get('CHEF_EXTRA_OPTIONS')
	parm['chef_delete_repo'] = settings.get('CHEF_DELETE_REPO')
	parm['chef_sudo_password'] = settings.get('CHEF_SUDO_PASSWORD')
	parm['chef_upgrade_packages'] = settings.get('CHEF_UPGRADE_PACKAGES')	
	@magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    super(@ec2_main, "Configure Chef", :opts => DECOR_ALL, :width => 750, :height => 350)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Chef Repository" )    
    chef_repository = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
 	chef_repository_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	chef_repository_button.icon = @magnifier
	chef_repository_button.tipText = "Browse..."
	chef_repository_button.connect(SEL_COMMAND) do
	   dialog = FXDirDialog.new(frame1, "Select Chef Repository Directory")
       dialog.directory = "#{ENV['EC2DREAM_HOME']}/chef/chef-repo"
	   if dialog.execute != 0
	      chef_repository.text = dialog.directory
       end
	end	
    FXLabel.new(frame1, "Foodcritic cookbook_path" )
    chef_foodcritic = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "e.g. site-cookbooks/mycompany_webserver" )    
    FXLabel.new(frame1, "chefspec spec files" )
    chef_rspec_test = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "e.g. site-cookbooks/*/spec/*_spec.rb" )
    FXLabel.new(frame1, "Run Chef Solo" )
    chef_apply = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    chef_apply.numVisible = 2      
    chef_apply.appendItem("true")	
    chef_apply.appendItem("false")
    chef_apply.setCurrentItem(0) 	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Run Chef Solo --why-run" )
    chef_why_run = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    chef_why_run.numVisible = 2      
    chef_why_run.appendItem("true")	
    chef_why_run.appendItem("false")
    chef_why_run.setCurrentItem(1) 	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Extra Chef Solo options" )
    chef_extra_options = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Delete Chef Repo" )
    chef_delete_repo = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    chef_delete_repo.numVisible = 2      
    chef_delete_repo.appendItem("true")	
    chef_delete_repo.appendItem("false")
    chef_delete_repo.setCurrentItem(1) 	
    FXLabel.new(frame1, "" )	
    FXLabel.new(frame1, "Sudo Password" )
    chef_sudo_password = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Upgrade Packages" )
    chef_upgrade_packages = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    chef_upgrade_packages.numVisible = 2      
    chef_upgrade_packages.appendItem("true")	
    chef_upgrade_packages.appendItem("false")
    chef_upgrade_packages.setCurrentItem(0) 	
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
        r['chef_repository']=chef_repository.text
        r['chef_foodcritic']=chef_foodcritic.text
        r['chef_rspec_test']=chef_rspec_test.text
		r['chef_apply']="false"	
        if chef_apply.itemCurrent?(0)
	      r['chef_apply']="true"
        end		
		r['chef_why_run']="false"	
        if chef_why_run.itemCurrent?(0)
	      r['chef_why_run']="true"
        end		
        r['chef_extra_options']=chef_extra_options.text
        r['chef_delete_repo']="false"	
        if chef_delete_repo.itemCurrent?(0)
	      r['chef_delete_repo']="true"
        end			
        r['chef_sudo_password']=chef_sudo_password.text
        r['chef_upgrade_packages']="false"	
        if chef_upgrade_packages.itemCurrent?(0)
	      r['chef_upgrade_packages']="true"
        end	
	    settings.put('CHEF_REPOSITORY',r['chef_repository'])
	    settings.put('CHEF_FOODCRITIC',r['chef_foodcritic'])
	    settings.put('CHEF_RSPEC_TEST',r['chef_rspec_test'])
        settings.put('CHEF_APPLY',r['chef_apply'])
		settings.put('CHEF_WHY_RUN',r['chef_why_run'])
		settings.put('CHEF_EXTRA_OPTIONS',r['chef_extra_options'])
		settings.put('CHEF_DELETE_REPO',r['chef_delete_repo'])
		settings.put('CHEF_SUDO_PASSWORD',r['chef_sudo_password'])
		settings.put('CHEF_UPGRADE_PACKAGES',r['chef_upgrade_packages'])
        settings.save		
        @saved = true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    chef_repository.text = parm['chef_repository'] if parm['chef_repository'] != nil 
    chef_foodcritic.text = parm['chef_foodcritic'] if parm['chef_foodcritic'] != nil
    chef_rspec_test.text = parm['chef_rspec_test'] if parm['chef_rspec_test'] != nil
	if parm['chef_apply'] != nil
	   chef_apply.setCurrentItem(0) if parm['chef_apply'] == "true"
	   chef_apply.setCurrentItem(1) if parm['chef_apply'] == "false"
	end
	if parm['chef_why_run'] != nil
	   chef_why_run.setCurrentItem(0) if parm['chef_why_run'] == "true"
	   chef_why_run.setCurrentItem(1) if parm['chef_why_run'] == "false"
	end
    chef_extra_options.text = parm['chef_extra_options'] if parm['chef_extra_options'] != nil
	if parm['chef_delete_repo'] != nil
	   chef_delete_repo.setCurrentItem(0) if parm['chef_delete_repo'] == "true"
	   chef_delete_repo.setCurrentItem(1) if parm['chef_delete_repo'] == "false"
	end
	chef_sudo_password.text = parm['chef_sudo_password'] if parm['chef_sudo_password'] != nil
	if parm['chef_upgrade_packages'] != nil
	   chef_upgrade_packages.setCurrentItem(0) if parm['chef_upgrade_packages'] == "true"
	   chef_upgrade_packages.setCurrentItem(1) if parm['chef_upgrade_packages'] == "false"
	end
  end 
  
  def saved
    @saved
  end

  def success
     @saved
  end
  
  
end
