def kitchen_cmd(cmd='list',instance=nil,debug=false)

  def gem_install(name,version=nil)
    puts "------>Installing #{name} #{version}....."
    begin
      cmd = "gem install  --no-ri --no-rdoc #{name}"
      cmd = cmd + " --version \"#{version}\"" if !version.nil?
      system cmd
      return true
    rescue
      puts $!
      return false
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
    # only try and install kitchen puppet once
    $kitchen_puppet_install_status = gem_install('kitchen-puppet') unless list.include? "kitchen-puppet" or $kitchen_puppet_install_status != nil
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
  when 'foodcritic','rspec','berks --debug','librarian-puppet install --verbose'
    c = "#{cmd} #{instance}"
    answer = FXMessageBox.question($ec2_main.tabBook,MBOX_YES_NO,"Confirm Command","Confirm Running #{c}")
    if answer == MBOX_CLICKED_YES
      if cmd == 'foodcritic'
        gem_install('foodcritic') if `gem list foodcritic -i`.include?('false')
      elsif cmd == 'berks --debug'
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
  when 'puppet-lint','rspec-puppet','puppet parser validate'
    cmd = 'rspec' if cmd == 'rspec-puppet'
    c = "#{cmd} #{instance}"
    answer = FXMessageBox.question($ec2_main.tabBook,MBOX_YES_NO,"Confirm Command","Confirm Running #{c}")
    if answer == MBOX_CLICKED_YES
      if cmd == 'puppet-lint'
        gem_install('puppet-lint') if `gem list puppet-lint -i`.include?('false')
      else
        gem_install('rspec-puppet') if `gem list rspec-puppet -i`.include?('false')
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

