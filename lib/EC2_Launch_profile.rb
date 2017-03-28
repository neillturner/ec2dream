require 'common/error_message'

class EC2_Launch_profile < FXImageFrame

  def initialize(owner, app)
    @ec2_main = owner
    @profile = ""
    @profile_folder = "launch"
    @properties = {}
    @bastion = {}
    @launch_loaded = false
  end

  def load(parm)
    puts "Launch.load"
    clear_panel
    @profile = parm
    #@profile_folder = "ops_launch" if @ec2_main.settings.openstack
    load_properties
  end

  def loaded
    @launch_loaded
  end

  def load_properties
      @properties = {}
      fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
      if File.exists?(fn)
        File.open(fn, 'r') do |properties_file|
          properties_file.read.each_line do |line|
            line.strip!
            if (line[0] != ?# and line[0] != ?=)
              i = line.index('=')
              if (i)
                @properties[line[0..i - 1].strip] = line[i + 1..-1].strip
              else
                @properties[line] = ''
              end
            end
          end
        end
        @launch_loaded = true
      else
        @launch_loaded = true
      end
  end

  def clear_panel
    puts "Launch.clear_panel"
    @profile = ""
    @properties = {}
    @bastion = {}
    @launch_loaded = false
  end

  def get(key)
    return @properties[key]
  end

  def google_get(key)
    return @properties[key]
  end

  def softlayer_get(key)
    return @properties[key]
  end

  def ops_get(key)
    return @properties[key]
  end

  def put(key,value)
    @properties[key] = value
  end

  def google_put(key,value)
    @properties[key] = value
  end

  def softlayer_put(key,value)
    @properties[key] = value
  end

  def ops_put(key,value)
     @properties[key] = value
  end

  def ops_save
    #@profile_folder = "ops_launch"
    save
  end


  def save
    puts "Launch.save"
    #@profile = @launch['Name'].text
    if @profile == nil or @profile == ""
      error_message("Error","No Server Name specified")
    else
      doc = ""
      @properties.each_pair do |key, value|
        if value != nil
          #puts "#{key}=#{value}\n"
          doc = doc + "#{key}=#{value}\n"
        end
      end
      fn = @ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder+"/"+@profile+".properties"
      begin
        File.open(fn, "w") do |f|
          f.write(doc)
        end
        @launch_loaded = true
      rescue
        puts "launch loaded false"
        @launch_loaded = false
      end
    end
  end

  def save_bastion(bastion=nil)
    @bastion = bastion if bastion != nil
    @properties['Bastion_Host'] = @bastion['bastion_host']
    @properties['Bastion_Port'] = @bastion['bastion_port']
    @properties['Bastion_User'] =  @bastion['bastion_user']
    @properties['Bastion_Ssh_Key'] = @bastion['bastion_ssh_key']
    @properties['Bastion_Putty_Key'] = @bastion['bastion_putty_key']
    @properties['Bastion_Password'] =  @bastion['bastion_password']
  end

end
