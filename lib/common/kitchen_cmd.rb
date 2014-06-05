def kitchen_cmd(cmd='list',instance=nil,debug=false)

 def gem_install(name,version=nil)
        puts "------>Installing #{name} #{version}....."
        begin
          cmd = "gem install  --no-ri --no-rdoc #{name}"
          cmd = cmd + " --version \"#{version}\"" if !version.nil?
          system cmd
        rescue
        puts $!
    end
  end
  repository = $ec2_main.settings.get('TEST_KITCHEN_PATH')
  case cmd
   when "list"
        list = `gem list`
        gem_install('test-kitchen')  unless list.include? "test-kitchen"
        gem_install('kitchen-vagrant') unless list.include? "kitchen-vagrant"
        gem_install('kitchen-ec2') unless list.include? "kitchen-ec2"
        gem_install('kitchen-ssh') unless list.include? "kitchen-ssh"
        gem_install('berkshelf','< 3') unless list.include? "berkshelf"
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
     config = []
     if File.exists?(config_file)
       config = YAML.load_file(config_file)
       #config = config.inspect
     else
       puts "ERROR: kitchen config file #{config_file} not found"
     end
     return config
   when "edit"
           editor = @ec2_main.settings.get_system('EXTERNAL_EDITOR')
           c="\"#{editor}\" \"#{repository}/.kitchen.yml\""
           puts c
           system(c)
   when 'foodcritic','rspec','berks --debug'
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

