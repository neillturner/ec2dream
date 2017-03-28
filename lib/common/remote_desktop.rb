def remote_desktop(server, password, user="Administrator", port="3389", local_port=nil, bastion_host=nil, bastion_port=nil, bastion_user=nil, bastion_password=nil)
  puts "remote_desktop #{server}, #{password}, #{user}, #{port}, #{local_port} #{bastion_host} #{bastion_port} #{bastion_user} #{bastion_password}"
  if user==nil or user==""
    user="Administrator"
  end
  # Console (integer, specify 0 for false and 1 for true)
  # RedirectDrives (integer, specify 0 for false and 1 for true)
  # RedirectPrinters (integer, specify 0 for false and 1 for true)
  if local_port !=nil and local_port != ""
    c = "cmd.exe /c \@start \"\" \""+ENV['EC2DREAM_HOME']+"/launchrdp/LaunchRDP.exe\" localhost #{local_port} #{user} localhost #{password} 0 1 0"
  else
    c = "cmd.exe /c \@start \"\" \""+ENV['EC2DREAM_HOME']+"/launchrdp/LaunchRDP.exe\" #{server} #{port} #{user} #{server} #{password} 0 1 0"
  end
  #if local_port !=nil and local_port != ""
  #  c = "cmd.exe /c \@start \"\" \""+ENV['EC2DREAM_HOME']+"/wfreerdp/wfreerdp.exe\" /v:localhost /port:#{local_port} /u:#{user} /d:localhost /p:#{password}"
  #else
  #  c = "cmd.exe /c \@start \"\" \""+ENV['EC2DREAM_HOME']+"/wfreerdp/wfreerdp.exe\" /v:#{server} /port:#{port} /u:#{user} /d:#{server} /p:#{password}"
  #end
  #c = c + " /g:#{bastion_host}:#{bastion_port} /gu:#{bastion_user} /gp:#{bastion_password} /gd:#{bastion_host}" if bastion_host
  puts c
  system(c)
end
