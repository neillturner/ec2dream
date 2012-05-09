require 'rubygems'
require 'fox16'


class EC2_Run 

  def initialize
     puts "EC2_run initialize"
  end 

  
  def scp(server, address, user, private_key, putty_key, password)
           s = server
	   if address != nil and address != ""
	      s = address
           end 
  	   if user == nil or user == ""
  	      user = "root"
  	   end	   
             if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
                 if putty_key  != nil and putty_key != "" 
                    c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/winscp/winscp.exe\" sftp://#{user}@#{s}  /privatekey="+"\"#{private_key}\""
  	         else
  	            c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/winscp/winscp.exe\" sftp://#{user}@#{s}  /password="+"\"#{password}\""  
  	         end
  	         puts c
  	         system(c)
             else
                c = "\nTo copy files to server instance use comand\n"
                c =  c+" scp -i #{private_key} <source> #{user}@#{s}\n\n"
                c =  c+"To copy files from server instance use comand\n"
  		c =  c+" scp -i #{private_key} #{user}@#{s} <source>\n" 
  		csvdialog = EC2_CSVDialog.new($ec2_main,c,"SCP Command")
                csvdialog.execute
             end
    end
   
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
  	             c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/putty/putty.exe\" -ssh "+s+" -pw "+"\""+password+"\""+" -l "+user
  	          end 
  	          puts c
  	          system(c)
              else
  	          te = "xterm"
                    if $ec2_main.settings.get_system('TERMINAL_EMULATOR') != nil and $ec2_main.settings.get_system('TERMINAL_EMULATOR') != ""
  	             te = $ec2_main.settings.get_system('TERMINAL_EMULATOR')
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
    
  
    def remote_desktop(server, password)
               # s = @server['Public_IP'].text
               # if s == nil or s == ""
  	       #  s = currentServer
  	     # end   
  	           c = "cmd.exe /c \@start \"\" \""+ENV['EC2DREAM_HOME']+"/launchrdp/LaunchRDP.exe\" "+s+" 3389 Administrator "+s+" "+pw+" 0 1 0"
  	           puts c
  	           system(c)
  end 
  
  
   def chef(server, address,  chef_node, ssh_user, private_key, password)
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
                 error_message("No ec2 ssh private key","No EC2_SSH_PRIVATE_KEY specified in Settings")
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
              sa = (ec2_server_name).split"."
              if sa.size>1
                 short_name = sa[0]
              end
             
              answer = FXMessageBox.question($ec2_main.tabBook,MBOX_YES_NO,"Confirm Chef Solo","Confirm Running of Chef-Solo for Node #{chef_node} on server #{ec2_server_name}")
              if answer == MBOX_CLICKED_YES
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
      	         return true
      	      end
      	      return false
   end
   
   def edit(filename)
      if filename != nil and filename != ""
   	 editor = $ec2_main.settings.get_system('EXTERNAL_EDITOR')
   	 puts "#{editor} #{filename}"
	 system editor+" "+filename
      end	 
   end	 
   
   def browser(url)
        if $ec2_main.settings.get_system('EXTERNAL_BROWSER') != nil and $ec2_main.settings.get_system('EXTERNAL_BROWSER') != ""
           if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
              c = "cmd.exe /c \@start \"\" /b \""+$ec2_main.settings.get_system('EXTERNAL_BROWSER')+"\"  "+url
              puts c
              system(c)
           else
              c = $ec2_main.settings.get_system('EXTERNAL_BROWSER')+" "+url
              puts c
              system(c)
           end
        else
           error_message("Error","No External Browser in Settings")
        end
   end     
   
   def error_message(title,message)
         FXMessageBox.warning($ec2_main,MBOX_OK,title,message)
   end
  
 
end
