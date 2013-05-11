def chef(server, address,  chef_node, ssh_user, private_key, password, platform="")
           # private_key = @ec2_main.settings.get('EC2_SSH_PRIVATE_KEY')    
           #chef_node = @secgrp
           #if @server['Chef_Node'].text != nil and @server['Chef_Node'].text != ""
	      #   chef_node = @server['Chef_Node'].text
           #end
           # ec2_server_name = @server['Public_DSN'].text
           #	    ssh_user = @server['EC2_SSH_User'].text
           chef_repository = $ec2_main.settings.get('CHEF_REPOSITORY')
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
              error_message("No Public DSN","This Server does not have a Public DSN")
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
             if platform != "windows"
              if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
                 ENV["EC2_CHEF_REPOSITORY"] = chef_repository
                 ENV["EC2_SSH_PRIVATE_KEY"] = private_key
                 c = "cmd.exe /c \@start \"chef-solo #{chef_node} #{ec2_server_name}\" \"#{ENV['EC2DREAM_HOME']}/chef/chef_push.bat\"  #{chef_node} #{ec2_server_name} #{ssh_user}"
   	         puts c
   	         system(c)
   	      else
   	         c = "#{ENV['EC2DREAM_HOME']}/chef/chef_push.sh #{chef_repository} #{chef_node} #{ec2_server_name} #{private_key} #{ssh_user}"
   	         puts c
   	         system(c)
   	      end
             else
    	        # handle windows servers (only from windows clients)
		if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
                  ENV["EC2_CHEF_REPOSITORY"] = chef_repository
                  ENV["EC2_SSH_PASSWORD"] = password
                  c = "cmd.exe /c \@start \"chef-solo #{chef_node} #{ec2_server_name}\" \"#{ENV['EC2DREAM_HOME']}/chef/chef_push_win.bat\"  #{chef_node} #{ec2_server_name} #{ssh_user}"
    	          puts c
    	          system(c)
    	        end   	      
    	     end
             return true
   	   end
   	   return false
end

