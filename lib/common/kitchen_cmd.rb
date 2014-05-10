def kitchen_cmd(cmd='list',instance=nil,debug=false)

  def gem_install(name)
	puts "------>Installing #{name}....."
	begin
       system "gem install  --no-ri --no-rdoc #{name}"
	rescue
	   puts $!
    end
  end
  repository = $ec2_main.settings.get('TEST_KITCHEN_PATH')
  case cmd
   when "list"
	gem_install('test-kitchen') if `gem list test-kitchen -i`.include?('false')
	gem_install('kitchen-vagrant') if `gem list kitchen-vagrant -i`.include?('false')
        gem_install('kitchen-ec2') if `gem list kitchen-ec2 -i`.include?('false')
	gem_install('berkshelf') if `gem list berkshelf -i`.include?('false')
	titles = []
        list = []
	`cd \"#{repository}\" && kitchen list #{instance}`.lines do |line|
    	      if titles == []
			     line=line.gsub('Last Action','Last-Action')
                 titles = line.split(' ')
			  else
			     line=line.gsub('<Not Created>','<Not-Created>')
				 line=line.gsub('Set Up','SetUp')
			     entries = line.split(' ')
				 i=0
				 h = {}
			     entries.each do |e|
				   h[titles[i]] = e
				   i=i+1
				 end
                 list.push(h)
              end
     end
     return list
   when 'config'
    if RUBY_VERSION <= "1.9.3"
      # ensure that Psych and not Syck is used for Ruby 1.9.2
      require 'yaml'
      YAML::ENGINE.yamler = 'psych'
    end
    require 'safe_yaml/load'
    config_file = "#{repository}/.kitchen/#{instance}.yml"
	config = nil
	if File.exists?(config_file)
       config = YAML.load_file(config_file)
       #config = config.inspect
	else
      puts "kitchen config file #{config_file} not found"
	end
	return config
   when "edit"
	   editor = @ec2_main.settings.get_system('EXTERNAL_EDITOR')
	   c="\"#{editor}\" \"#{repository}/.kitchen.yml\""
	   puts c
	   system(c)
   when 'foodcritic','rspec'
       c = "#{cmd} #{instance}"
       answer = FXMessageBox.question($ec2_main.tabBook,MBOX_YES_NO,"Confirm Command","Confirm Running #{c}")
       if answer == MBOX_CLICKED_YES
	      if cmd == 'foodcritic'
 		   gem_install('foodcritic') if `gem list foodcritic -i`.include?('false')
   		  else
		   gem_install('chefspec') if `gem list chefspec -i`.include?('false')
		   gem_install('fauxhai') if !`gem list`.lines.grep(/^fauxhai \(.*\)/)
   		  end
          if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
             c = "cmd.exe /c \@start \"kitchen\" /D \"#{repository}\" #{c}"
   	         puts c
   	         system(c)
   	      else
		     c = " cd #{repository} && #{c}"
   	         puts c
   	         system(c)
   	         puts "kitchen #{cmd} return message #{$?}"
   	      end
       end
   else
     answer = FXMessageBox.question($ec2_main.tabBook,MBOX_YES_NO,"Confirm Kitchen Command","Confirm Running kitchen #{cmd} for instance #{instance}")
     if answer == MBOX_CLICKED_YES
        c="kitchen #{cmd} #{instance}"
        c=c+" -l debug" if debug
        if RUBY_PLATFORM.index("mswin") != nil  or RUBY_PLATFORM.index("i386-mingw32") != nil
             c = "cmd.exe /c \@start \"kitchen\" /D \"#{repository}\" #{c}"
   	         puts c
   	         system(c)
   	    else
		     c = " cd #{repository} && #{c}"
   	         puts c
   	         system(c)
   	         puts "kitchen #{cmd} return message #{$?}"
   	    end
     end
   end
 end

