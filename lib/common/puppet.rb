def puppet(server, address,  puppet_manifest, ssh_user, private_key, password, platform="", local_port="", puppet_roles="" )
           # private_key = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY')    
           #chef_node = @secgrp
           #if @server['Chef_Node'].text != nil and @server['Chef_Node'].text != ""
	      #   chef_node = @server['Chef_Node'].text
           #end
           # ec2_server_name = @server['Public_DSN'].text
           #	    ssh_user = @server['EC2_SSH_User'].text
           puppet_repository = $ec2_main.settings.get('PUPPET_REPOSITORY')
		   puppet_module_path = $ec2_main.settings.get('PUPPET_MODULE_PATH')
		   puppet_syntax_check = $ec2_main.settings.get('PUPPET_SYNTAX_CHECK')
	       puppet_rspec_test  = $ec2_main.settings.get('PUPPET_RSPEC_TEST')
           puppet_apply  = $ec2_main.settings.get('PUPPET_APPLY')
	       puppet_apply_noop = $ec2_main.settings.get('PUPPET_APPLY_NOOP')
	       puppet_extra_options = $ec2_main.settings.get('PUPPET_EXTRA_OPTIONS')
	       puppet_delete_repo = $ec2_main.settings.get('PUPPET_DELETE_REPO')
		   puppet_sudo_password = $ec2_main.settings.get('PUPPET_SUDO_PASSWORD')
	       puppet_upgrade_packages = $ec2_main.settings.get('PUPPET_UPGRADE_PACKAGES')
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
           answer = FXMessageBox.question($ec2_main.tabBook,MBOX_YES_NO,"Server - #{server} #{short_name}","Server #{server} #{short_name} - Confirm Running Puppet Apply\n for Manifest #{puppet_manifest} and Puppet Roles #{puppet_roles} ")
           if answer == MBOX_CLICKED_YES
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
				if puppet_module_path != nil and puppet_module_path != ""
				 puppet_options = puppet_options+" -d \"#{puppet_module_path}\""
				end 
				if puppet_syntax_check != nil and puppet_syntax_check != ""
				 puppet_options = puppet_options+" -y \"#{puppet_syntax_check}\""
				end	
				if puppet_rspec_test != nil and puppet_rspec_test != ""
				   puppet_options = puppet_options+" -r \"#{puppet_rspec_test}\""
				end	
		        if puppet_apply != nil and puppet_apply == "false"
				   puppet_options = puppet_options+" -u "
				end		   
		        if puppet_apply_noop != nil and puppet_apply_noop == "true"
				   puppet_options = puppet_options+" -o "
				end	
		        if puppet_extra_options != nil and puppet_extra_options != ""
				   puppet_options = puppet_options+" -x \"#{puppet_extra_options}\""
				end	
		        if puppet_delete_repo != nil and puppet_delete_repo == "true"
				   puppet_options = puppet_options+" -n "
				end
		         if puppet_sudo_password != nil and puppet_sudo_password != ""
				   puppet_options = puppet_options+" -t \"#{puppet_sudo_password}\""
				end	
		        if puppet_upgrade_packages != nil and puppet_upgrade_packages == "false"
				   puppet_options = puppet_options+" -z "
				end
				
				puppet_options = puppet_options+" -e hiera.yaml"	
                ENV["EC2_PUPPET_REPOSITORY"] = puppet_repository
                ENV["EC2_PUPPET_PARAMETERS"] = puppet_options				
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
             return true
		end   
   	   	return false
end

