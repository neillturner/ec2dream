  def remote_desktop(server, password, user="Administrator", port="3389", local_port=nil)
                   puts "remote_desktop #{server}, #{password}, #{user}, #{port}, #{local_port}"
                   if user==nil or user==""
                      user="Administrator"
                   end
                   if local_port !=nil and local_port != ""
                      c = "cmd.exe /c \@start \"\" \""+ENV['EC2DREAM_HOME']+"/launchrdp/LaunchRDP.exe\" localhost #{local_port} #{user} localhost #{password} 0 1 0"
                   else
	              c = "cmd.exe /c \@start \"\" \""+ENV['EC2DREAM_HOME']+"/launchrdp/LaunchRDP.exe\" #{server} #{port} #{user} #{server} #{password} 0 1 0"
	           end
	           puts c
	           system(c)
end 
