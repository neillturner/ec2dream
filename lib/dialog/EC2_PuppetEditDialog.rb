require 'rubygems'
require 'fox16'
require 'common/error_message'

include Fox

class EC2_PuppetEditDialog < FXDialogBox

  def initialize(owner, server, address,  puppet_manifest, ssh_user, private_key, password, platform, local_port, puppet_roles)
    puts "puppet #{server}, #{address},  #{puppet_manifest}, #{ssh_user}, #{private_key}, #{password}, #{platform}, #{local_port}, #{ puppet_roles}"
     @saved = false
    @ec2_main = owner
	settings = @ec2_main.settings
    parm = {}
	puppet_repository = settings.get('PUPPET_REPOSITORY')
	parm['puppet_module_path'] = settings.get('PUPPET_MODULE_PATH')
    parm['puppet_apply'] = settings.get('PUPPET_APPLY')
	parm['puppet_apply_noop'] = settings.get('PUPPET_APPLY_NOOP')
	parm['puppet_extra_options'] = settings.get('PUPPET_EXTRA_OPTIONS')
	parm['puppet_delete_repo'] = settings.get('PUPPET_DELETE_REPO')
	parm['puppet_sudo_password'] = settings.get('PUPPET_SUDO_PASSWORD')
	parm['puppet_upgrade_packages'] = settings.get('PUPPET_UPGRADE_PACKAGES')	
	@magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
          if puppet_manifest == nil or puppet_manifest == ""
	         puppet_manifest = 'init.pp'
           end       	    
    	      ec2_server_name = server
    	      if address != nil and address != ""
	         ec2_server_name = address
           end 
           #node_name = "#{chef_repository}/nodes/#{chef_node}.json"
           if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
               if puppet_repository != nil
                 puppet_repository = puppet_repository.gsub('/','\\') 
               end
               if private_key != nil
                  private_key = private_key.gsub('/','\\') 
               end
               #node_name = node_name.gsub('/','\\') 
           end
           if puppet_repository == nil or puppet_repository == ""
              error_message("No Puppet Repository","No PUPPET_REPOSITORY specified in Settings")
              return false
           end
           if private_key == nil or private_key == ""  and (password == nil or password == "")
              error_message("No ec2 ssh private key","No EC2_SSH_PRIVATE_KEY specified")
              return false
           end
           #if !File.exists?(node_name) 
           #   error_message("No Chef Node file","No Chef Node file #{node_name} for this server")
           #   return false
           #end
           if ec2_server_name == nil or ec2_server_name == ""
              error_message("No Public of Private DSN","This Server does not have a Public or Private DSN")
              return false
           end
           short_name = ec2_server_name
           if ec2_server_name.size > 16
              sa = (ec2_server_name).split"."
              if sa.size>1
                 short_name = sa[0]
              end
           end	
    super(@ec2_main, "Puppet", :opts => DECOR_ALL, :width => 550, :height => 275)
	page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Puppet Module Path" )
    puppet_module_path = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "(separated by colons)" )
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
    frame2 = FXMatrix.new(page1, 1, :opts => MATRIX_BY_COLUMNS|LAYOUT_CENTER_X)
	puppet_message = FXLabel.new(frame2, "Server #{server} #{short_name} - Confirm Running Puppet Apply\n for Manifest #{puppet_manifest} and Puppet Roles #{puppet_roles} ", :opts => LAYOUT_CENTER_X )
	FXLabel.new(frame2, "" )
	frame3 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    yes = FXButton.new(frame3, "   &Yes   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    no = FXButton.new(frame3, "   &No   ", nil, self, ID_CANCEL, FRAME_RAISED|LAYOUT_CENTER_X|LAYOUT_SIDE_BOTTOM)
    no.connect(SEL_COMMAND) do |sender, sel, data|
            self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end  	
    yes.connect(SEL_COMMAND) do |sender, sel, data|
	    r = {}
        r['puppet_module_path']=puppet_module_path.text
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
	    settings.put('PUPPET_MODULE_PATH',r['puppet_module_path'])
        settings.put('PUPPET_APPLY',r['puppet_apply'])
		settings.put('PUPPET_APPLY_NOOP',r['puppet_apply_noop'])
		settings.put('PUPPET_EXTRA_OPTIONS',r['puppet_extra_options'])
		settings.put('PUPPET_DELETE_REPO',r['puppet_delete_repo'])
		settings.put('PUPPET_SUDO_PASSWORD',r['puppet_sudo_password'])
		settings.put('PUPPET_UPGRADE_PACKAGES',r['puppet_upgrade_packages'])
        settings.save		
        @saved = true
                puppet_options = "-iv"
				if private_key != nil and private_key !=""
				   puppet_options = puppet_options+"k #{private_key}"
                else
                   puppet_options = puppet_options+"p #{password}"				
				end 
				puppet_options = puppet_options+" -m  #{puppet_manifest}" 
	            if ssh_user != nil and ssh_user != ""
				   puppet_options = puppet_options+" -s #{ssh_user}" 
                end
                if local_port != nil and local_port != ""
				   puppet_options = puppet_options+" -l #{local_port}" 
                end	
				if puppet_roles != nil and puppet_roles != ""
				   roles = puppet_roles.split(',')
				   facts = ""
				   i=0
				   roles.each do |r|
				      i=i+1 
                      if facts != ""				   
   				       facts=facts+",role_name#{i}=#{r}"
					  else
                       facts=facts+"role_name#{i}=#{r}"
                      end					  
                   end					  
				   puppet_options = puppet_options+" -f \"#{facts}\"" 
                end	
				if r['puppet_module_path'] != nil and r['puppet_module_path'] != ""
				 puppet_options = puppet_options+" -d \"#{r['puppet_module_path']}\""
				end 
		        if r['puppet_apply'] != nil and r['puppet_apply'] == "false"
				   puppet_options = puppet_options+" -u "
				end		   
		        if r['puppet_apply_noop'] != nil and r['puppet_apply_noop'] == "true"
				   puppet_options = puppet_options+" -o "
				end	
		        if r['puppet_extra_options'] != nil and r['puppet_extra_options'] != ""
				   puppet_options = puppet_options+" -x \"#{r['puppet_extra_options']}\""
				end	
		        if r['puppet_delete_repo'] != nil and r['puppet_delete_repo'] == "true"
				   puppet_options = puppet_options+" -n "
				end
		         if r['puppet_sudo_password'] != nil and r['puppet_sudo_password'] != ""
				   puppet_options = puppet_options+" -t \"#{r['puppet_sudo_password']}\""
				end	
		        if r['puppet_upgrade_packages'] != nil and r['puppet_upgrade_packages'] == "false"
				   puppet_options = puppet_options+" -z "
				end
				
				puppet_options = puppet_options+" -e hiera.yaml"	
                ENV["EC2_PUPPET_REPOSITORY"] = puppet_repository
                ENV["EC2_PUPPET_PARAMETERS"] = puppet_options	
				if `gem list pocketknife_puppet -i`.include?('false')
			       puts "------>Installing pocketknife_puppet....."
	               begin
                      system "gem install --no-ri --no-rdoc pocketknife_puppet"
	               rescue
	                  puts $!
                   end
 	            end	
   	
                if platform != "windows"
                 if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
                   c = "cmd.exe /c \@start \"puppet apply #{ec2_server_name}\" \"#{ENV['EC2DREAM_HOME']}/puppet/puppet_push.bat\"  #{ec2_server_name}"
			       puts c
   	               system(c)
   	             else
   	               c = "#{ENV['EC2DREAM_HOME']}/puppet/puppet_push.sh  #{ec2_server_name}"
 			       puts c
   	               system(c)
   	               puts "return message #{$?}"
   	             end
                else
    	        # handle windows servers (only from windows clients)
		        #if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
                #  ENV["EC2_CHEF_REPOSITORY"] = chef_repository
                #  ENV["EC2_SSH_PASSWORD"] = password
                #  c = "cmd.exe /c \@start \"chef-solo #{puppet_manifest} #{ec2_server_name}\" \"#{ENV['EC2DREAM_HOME']}/chef/chef_push_win.bat\"  #{puppet_manifest} #{ec2_server_name} #{ssh_user} #{local_port}"
    	        #  puts c
    	        #  system(c)
    	        #end   	      
    	        end		
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    puppet_module_path.text = parm['puppet_module_path'] if parm['puppet_module_path'] != nil
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
