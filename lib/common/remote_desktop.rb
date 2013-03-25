  def remote_desktop(server, password, user="Administrator")
                   if user==nil or user==""
                      user="Administrator"
                   end
	           c = "cmd.exe /c \@start \"\" \""+ENV['EC2DREAM_HOME']+"/launchrdp/LaunchRDP.exe\" #{server} 3389 #{user} #{server} #{password} 0 1 0"
	           puts c
	           system(c)
end 
