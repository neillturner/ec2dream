def command_runner(server, address, command, ssh_user, private_key, password, platform="")
           if private_key == nil or private_key == ""  and (password == nil or password == "")
              error_message("No ec2 ssh private key","No EC2_SSH_PRIVATE_KEY specified")
              return false
           end
           ec2_server_name = server
    	   if address != nil and address != ""
	      ec2_server_name = address
           end            
           if ec2_server_name == nil or ec2_server_name == ""
              error_message("No Public or Private DSN","This Server does not have a Public or Private DSN")
              return false
           end
           short_name = ec2_server_name
           if ec2_server_name.size > 16
              sa = (ec2_server_name).split"."
              if sa.size>1
                 short_name = sa[0]
              end
           end
           answer = FXMessageBox.question($ec2_main.tabBook,MBOX_YES_NO,"Confirm Execute Command","Confirm Running of #{command} on server #{short_name}")
           if answer == MBOX_CLICKED_YES
              if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
                 if private_key != nil
		    private_key = private_key.gsub('/','\\') 
                 end
                 c = "start \"run command on #{ec2_server_name}\" cmd.exe /k ruby \"#{ENV['EC2DREAM_HOME']}/lib/common/command_rye.rb\" #{ec2_server_name} -u #{ssh_user} -k \"#{private_key}\" -c \"#{command}\""
                 puts c
   	         system(c)
   	      else
   	         c = "ruby #{ENV['EC2DREAM_HOME']}/lib/common/command_rye.rb #{ec2_server_name} -u #{ssh_user} -k \"#{private_key}\" -c \"#{command}\""
   	         puts c
   	         system(c)
   	      end
              return true
   	   end
   	   return false
end

