 def ssh_tunnel(server, address, user, private_key, putty_key, password, address_port, local_port, bastion_host, bastion_port, bastion_user, bastion_private_key, bastion_putty_key, bastion_password="")
         puts "ssh_tunnel #{server}, #{address}, #{user}, #{private_key}, #{putty_key}, #{password}, #{address_port}, #{local_port}, #{bastion_host}, #{bastion_port} #{bastion_user}, #{bastion_private_key}, #{bastion_putty_key}, #{bastion_password}"
         s = server
         if address != nil and address != ""
            s = address
         end   
	    if user == nil or user == ""
	       user = "root"
	    end
	    if local_port == nil or local_port == ""
	       puts "ERROR: local port not specified"
	       return 
	    end
	    if bastion_host == nil or bastion_host == ""
	       puts "ERROR: bastion host not specified"
	       return 
	    end
            if bastion_port == nil or bastion_port == ""
	       puts "ERROR: bastion port not specified"
	       return 
	    end
	    if address_port == nil or address_port == "" 
	       address_port = 22
	    end   
           if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
		       puts "WARNING: Starting ssh tunnel" 
               if putty_key  != nil and putty_key != "" 
	             c = "cmd.exe /c \@start \"ssh tunnel port #{local_port}\" /b \""+ENV['EC2DREAM_HOME']+"/putty/putty.exe\" -ssh #{bastion_host} -i "+"\""+bastion_putty_key+"\""+" -l #{bastion_user} -L #{local_port}:#{s}:#{address_port}"
	          else 
	             puts "WARNING: no Putty Private Key specified" 
	             c = "cmd.exe /c \@start \"ssh tunnel port #{local_port}\" /b \""+ENV['EC2DREAM_HOME']+"/putty/putty.exe\" -ssh #{bastion_host} -pw "+"\""+bastion_password+"\""+" -l #{bastion_user} -L #{local_port}:#{s}:#{address_port}"
	          end
                  if bastion_port != nil and bastion_port != ""
	             c = "#{c} -P #{bastion_port}"
	          end		          
	          puts c
	          system(c)
            else
	          te = "xterm"
                 if $ec2_main.settings.get_system('TERMINAL_EMULATOR') != nil and $ec2_main.settings.get_system('TERMINAL_EMULATOR') != ""
	             te = $ec2_main.settings.get_system('TERMINAL_EMULATOR')
	          end 
	          if private_key == nil or private_key == ""
	            puts "WARNING: no SSH Private Key specified" 
	          end 
	          if RUBY_PLATFORM.index("linux") != nil
	             if te == "xterm"
                        c = "xterm -hold -e ssh -i  #{bastion_private_key} -l #{user} -L #{local_port}:#{s}:#{address_port} #{bastion_host} &"
                    else 
                        c = te+ " -x ssh -i #{bastion_host_private_key} -l #{user} -L #{local_port}:#{s}:#{address_port} #{bastion_host} &"
                    end
	          else
		     if te == "xterm"
                        c = "xterm -e ssh -i #{bastion_private_key} -l #{user} -L #{local_port}:#{s}:#{address_port} #{bastion_host} &"
                    else 
                        c = te+ " -x ssh -i #{bastion_private_key} -l #{user} -L #{local_port}:#{s}:#{address_port} #{bastion_host} &"
                    end	          
	          end	          
	          puts c
	          system(c)
           end
 end 
 
