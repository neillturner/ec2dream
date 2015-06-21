def scp(server, address, user, private_key, putty_key, password, local_port=nil)
  s = server
  if address != nil and address != ""
    s = address
  end 
  if user == nil or user == ""
    user = "root"
  end	   
  if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
    if local_port != nil and local_port != ""
      puts "WARNING: accessing server via ssh tunnel"
      c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/winscp/winscp.exe\" sftp://#{user}@localhost:#{local_port}  /privatekey="+"\"#{putty_key}\""
    elsif putty_key  != nil and putty_key != "" 
      c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/winscp/winscp.exe\" sftp://#{user}@#{s}  /privatekey="+"\"#{putty_key}\""
    else
      puts "WARNING: no Putty Private Key specified" 
      # the password parameter doesn't seem to work so have to manually re-enter password
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
