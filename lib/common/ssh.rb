def ssh(server, address, user, private_key, putty_key, password, local_port=nil, address_port=nil)
  puts " ssh #{server}, #{address}, #{user}, #{private_key}, #{putty_key}, #{password}, #{local_port}"
  s = server
  if address != nil and address != ""
    s = address
  end
  if user == nil or user == ""
    user = "root"
  end
  if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("mingw") != nil
    if local_port != nil and local_port != ""
      puts "WARNING: accessing server maybe via ssh tunnel"
      s = "localhost"
      #c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/putty/putty.exe\" -ssh localhost -P #{local_port} -i "+"\""+putty_key+"\""+" -l "+user
    end
    if putty_key  != nil and putty_key != ""
      c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/putty/putty.exe\" -ssh "+s+" -i "+"\""+putty_key+"\""+" -l "+user
    else
      puts "WARNING: no Putty Private Key specified"
      c = "cmd.exe /c \@start \"\" /b \""+ENV['EC2DREAM_HOME']+"/putty/putty.exe\" -ssh #{s} -pw "+"\"#{password}\""+" -l #{user}"
    end
    if local_port != nil and local_port != ""
      c = c +" -P #{local_port}"
    end
    if address_port != nil and address_port != ""
      c = c +" -P #{address_port}"
    end
    puts c
    system(c)
  else
    # TO DO add localhost for non-windows platforms.
    te = "xterm"
    if $ec2_main.settings.get_system('TERMINAL_EMULATOR') != nil and $ec2_main.settings.get_system('TERMINAL_EMULATOR') != ""
      te = $ec2_main.settings.get_system('TERMINAL_EMULATOR')
    end
    if private_key == nil or private_key == ""
      puts "WARNING: no SSH Private Key specified"
    end
    s = server if RUBY_PLATFORM.index("linux") != nil and te != "xterm"
    if RUBY_PLATFORM.index("linux") != nil
      if te == "xterm"
        c = "xterm -hold -e"
      else
        c = te+ " -x"
      end
    else
      if te == "xterm"
        c = "xterm -e"
      else
        c = te+ " -x"
      end
    end
    if address_port != nil and address_port != ""
      c = c+" ssh -i #{private_key} localhost -l #{user} -p #{address_port} &"
    elsif local_port != nil and local_port != ""
      puts "WARNING: accessing server via ssh tunnel"
      c = c+" ssh -i #{private_key} localhost -l #{user} -p #{local_port} &"
    else
      c = c+" ssh -i #{private_key} #{s} -l #{user} &"
    end
    puts c
    system(c)
  end
end
