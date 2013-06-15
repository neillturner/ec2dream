 def ssh(server, address, user, private_key, putty_key, password)
         s = server
         if address != nil and address != ""
            s = address
         end   
	    if user == nil or user == ""
	       user = "root"
	    end
           if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
               if putty_key  != nil and putty_key != "" 
	             c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/putty/putty.exe\" -ssh "+s+" -i "+"\""+putty_key+"\""+" -l "+user
	          else 
	             puts "WARNING: no Putty Private Key specified" 
	             c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/putty/putty.exe\" -ssh "+s+" -pw "+"\""+password+"\""+" -l "+user
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
                        c = "xterm -hold -e ssh -i "+private_key+" "+s+" -l "+user+" &"
                    else 
                        c = te+ " -x ssh -i "+private_key+" "+server+" -l "+user+" &"
                    end
	          else
		     if te == "xterm"
                        c = "xterm -e ssh -i "+private_key+" "+s+" -l "+user+" &"
                    else 
                        c = te+ " -x ssh -i "+private_key+" "+s+" -l "+user+" &"
                    end	          
	          end	          
	          puts c
	          system(c)
           end
 end 
 
