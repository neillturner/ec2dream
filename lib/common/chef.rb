def chef(server, address,  chef_node, ssh_user, private_key, password, platform="", local_port="")
           puts "chef #{server}, #{address},  #{chef_node}, #{ssh_user}, #{private_key}, #{password}, #{platform}, #{local_port}"
           # private_key = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY')    
           #chef_node = @secgrp
           #if @server['Chef_Node'].text != nil and @server['Chef_Node'].text != ""
	      #   chef_node = @server['Chef_Node'].text
           #end
           # ec2_server_name = @server['Public_DSN'].text
           #	    ssh_user = @server['EC2_SSH_User'].text
           chef_repository = $ec2_main.settings.get('CHEF_REPOSITORY')
		   chef_foodcritic = $ec2_main.settings.get('CHEF_FOODCRITIC')
	       chef_rspec_test  = $ec2_main.settings.get('CHEF_RSPEC_TEST')
           chef_apply  = $ec2_main.settings.get('CHEF_APPLY')
	       chef_why_run = $ec2_main.settings.get('CHEF_WHY_RUN')
	       chef_extra_options = $ec2_main.settings.get('CHEF_EXTRA_OPTIONS')
	       chef_delete_repo = $ec2_main.settings.get('CHEF_DELETE_REPO')
		   chef_sudo_password = $ec2_main.settings.get('CHEF_SUDO_PASSWORD')
	       chef_upgrade_packages = $ec2_main.settings.get('CHEF_UPGRADE_PACKAGES')		   
           if chef_node == nil or chef_node == ""
	         chef_node = server
           end       	    
    	      ec2_server_name = server
    	      if address != nil and address != ""
	         ec2_server_name = address
           end 
           node_name = "#{chef_repository}/nodes/#{chef_node}.json"
           if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
               if chef_repository != nil
                 chef_repository = chef_repository.gsub('/','\\') 
               end
               if private_key != nil
                  private_key = private_key.gsub('/','\\') 
               end
               node_name = node_name.gsub('/','\\') 
           end
           if chef_repository == nil or chef_repository == ""
              error_message("No Chef Repository","No CHEF_REPOSITORY specified in Settings")
              return false
           end
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
           answer = FXMessageBox.question($ec2_main.tabBook,MBOX_YES_NO,"Confirm Chef Solo","Confirm Running of Chef-Solo for Node #{chef_node} on server #{short_name}")
           if answer == MBOX_CLICKED_YES
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
			 if chef_foodcritic != nil and chef_foodcritic != ""
				 chef_options = chef_options+" -f \"#{chef_foodcritic}\""
			 end	
			 if chef_rspec_test != nil and chef_rspec_test != ""
				chef_options = chef_options+" -r \"#{chef_rspec_test}\""
			 end	
		     if chef_apply != nil and chef_apply == "false"
				chef_options = chef_options+" -u "
			 end		   
		     if chef_why_run != nil and chef_why_run == "true"
				chef_options = chef_options+" -w "
			 end	
		     if chef_extra_options != nil and chef_extra_options != ""
				chef_options = chef_options+" -x \"#{chef_extra_options}\""
			 end	
		     if chef_delete_repo != nil and chef_delete_repo == "true"
				chef_options = chef_options+" -n "
			 end
		     if chef_sudo_password != nil and chef_sudo_password != ""
				chef_options = chef_options+" -t \"#{chef_sudo_password}\""
			 end	
		     if chef_upgrade_packages != nil and chef_upgrade_packages == "false"
				chef_options = chef_options+" -z "
			 end			 
             ENV["EC2_CHEF_REPOSITORY"] = chef_repository
             ENV["EC2_CHEF_PARAMETERS"] = chef_options			 
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
             return true
   	   end
   	   return false
end

