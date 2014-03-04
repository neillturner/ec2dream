require 'rubygems'
require 'fox16'
require 'common/error_message'

include Fox

class EC2_ChefEditDialog < FXDialogBox

  def initialize(owner, server, address, chef_node, ssh_user, private_key, password, platform="", local_port="")
    puts "EC2_ChefEditDialog #{server}, #{address},  #{chef_node}, #{ssh_user}, #{private_key}, #{password}, #{platform}, #{local_port}"
    @saved = false
    @ec2_main = owner
	settings = @ec2_main.settings
	parm = {}
	chef_repository = settings.get('CHEF_REPOSITORY')
    parm['chef_apply'] = settings.get('CHEF_APPLY')
	parm['chef_why_run'] = settings.get('CHEF_WHY_RUN')
	parm['chef_extra_options'] = settings.get('CHEF_EXTRA_OPTIONS')
	parm['chef_delete_repo'] = settings.get('CHEF_DELETE_REPO')
	parm['chef_sudo_password'] = settings.get('CHEF_SUDO_PASSWORD')
	parm['chef_upgrade_packages'] = settings.get('CHEF_UPGRADE_PACKAGES')	
	@magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
		   if chef_node == nil or chef_node == ""
	         chef_node = server
           end       	    
    	      ec2_server_name = server
    	      if address != nil and address != ""
	         ec2_server_name = address
           end 
           node_name = "#{chef_repository}/nodes/#{chef_node}.json"
           if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
               if private_key != nil
                  private_key = private_key.gsub('/','\\') 
               end
               node_name = node_name.gsub('/','\\') 
           end
           #if chef_repository == nil or chef_repository == ""
           #   error_message("No Chef Repository","No CHEF_REPOSITORY specified in Settings")
           #   return false
           #end
           if private_key == nil or private_key == ""  and (password == nil or password == "")
              error_message("No ec2 ssh private key","No EC2_SSH_PRIVATE_KEY specified")
              return false
           end
           if !File.exists?(node_name) 
              error_message("No Chef Node file","No Chef Node file #{node_name} for this server")
              return false
           end
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
    super(@ec2_main, "Chef", :opts => DECOR_ALL, :width => 500, :height => 275)
	page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
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
    frame2 = FXMatrix.new(page1, 1, :opts => MATRIX_BY_COLUMNS|LAYOUT_CENTER_X)
	chef_message = FXLabel.new(frame2, "Confirm Running of Chef-Solo for Node #{chef_node} on server #{short_name}", :opts => LAYOUT_CENTER_X )
	FXLabel.new(frame2, "" )
	frame3 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    yes = FXButton.new(frame3, "   &Yes   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    no = FXButton.new(frame3, "   &No   ", nil, self, ID_CANCEL, FRAME_RAISED|LAYOUT_CENTER_X|LAYOUT_SIDE_BOTTOM)
    no.connect(SEL_COMMAND) do |sender, sel, data|
            self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end  	
    yes.connect(SEL_COMMAND) do |sender, sel, data|
	    r = {}
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
	    settings.put('CHEF_APPLY',r['chef_apply'])
		settings.put('CHEF_WHY_RUN',r['chef_why_run'])
		settings.put('CHEF_EXTRA_OPTIONS',r['chef_extra_options'])
		settings.put('CHEF_DELETE_REPO',r['chef_delete_repo'])
		settings.put('CHEF_SUDO_PASSWORD',r['chef_sudo_password'])
		settings.put('CHEF_UPGRADE_PACKAGES',r['chef_upgrade_packages'])
        settings.save		
        @saved = true

		     if local_port == nil or local_port == ""
                ssh_user = "root" if ssh_user == nil or ssh_user == ""
             end
		     chef_options = "-iv"
			 if private_key != nil and private_key !=""
				chef_options = chef_options+"k #{private_key}"
             else
                chef_options = chef_options+"p #{password}"				
			 end
             if ssh_user != nil and ssh_user != ""
				chef_options = chef_options+" -s #{ssh_user}" 
             end
             if local_port != nil and local_port != ""
			    chef_options =chef_options+" -l #{local_port}" 
             end
		     if r['chef_apply'] != nil and r['chef_apply'] == "false"
				chef_options = chef_options+" -u "
			 end		   
		     if r['chef_why_run'] != nil and r['chef_why_run'] == "true"
				chef_options = chef_options+" -w "
			 end	
		     if r['chef_extra_options'] != nil and r['chef_extra_options'] != ""
				chef_options = chef_options+" -x \"#{r['chef_extra_options']}\""
			 end	
		     if r['chef_delete_repo'] != nil and r['chef_delete_repo'] == "true"
				chef_options = chef_options+" -n "
			 end
		     if r['chef_sudo_password'] != nil and r['chef_sudo_password'] != ""
				chef_options = chef_options+" -t \"#{r['chef_sudo_password']}\""
			 end	
		     if r['chef_upgrade_packages'] != nil and r['chef_upgrade_packages'] == "false"
				chef_options = chef_options+" -z "
			 end
             if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
               if chef_repository != nil
                 chef_repository = chef_repository.gsub('/','\\') 
               end	
             end			   
             ENV["EC2_CHEF_REPOSITORY"] = chef_repository
             ENV["EC2_CHEF_PARAMETERS"] = chef_options	
			 if `gem list pocketknife_ec2dream -i`.include?('false')
			    puts "------>Installing pocketknife_ec2dream....."
	            begin
                   system "gem install --no-ri --no-rdoc pocketknife_ec2dream"
	            rescue
	               puts $!
                end
 	         end
			 if `gem list pocketknife_windows -i`.include?('false')
			    puts "------>Installing pocketknife_windows....."
	            begin
                   system "gem install --no-ri --no-rdoc pocketknife_windows"
	            rescue
	               puts $!
                end
 	         end				 
             if platform != "windows"
              if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
                  c = "cmd.exe /c \@start \"chef-solo #{chef_node} #{ec2_server_name}\" \"#{ENV['EC2DREAM_HOME']}/chef/chef_push.bat\"  #{chef_node} #{ec2_server_name}"
   	              puts c
   	              system(c)
   	          else
   	              c = "#{ENV['EC2DREAM_HOME']}/chef/chef_push.sh #{chef_repository} #{chef_node} #{ec2_server_name} #{private_key}"
   	              puts c
   	              system(c)
   	              puts "return message #{$?}"
   	          end
            else
			    # TO DO  ******
    	        # handle windows servers (only from windows clients)
		        if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
                  ENV["EC2_CHEF_REPOSITORY"] = chef_repository
                  ENV["EC2_SSH_PASSWORD"] = password
                  ssh_user = "root" if local_port == nil or local_port == ""
                  c = "cmd.exe /c \@start \"chef-solo #{chef_node} #{ec2_server_name}\" \"#{ENV['EC2DREAM_HOME']}/chef/chef_push_win.bat\"  #{chef_node} #{ec2_server_name} #{ssh_user} #{local_port}"
    	          puts c
    	          system(c)
    	        end   	      
    	     end
         self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
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
