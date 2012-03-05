
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_EnvDialog < FXDialogBox

  def initialize(owner)
    @curr_env = ""
    @ec2_main = owner
    envs = nil
    local_repository = "#{ENV['EC2DREAM_HOME']}/env"
    if !Dir.exists? local_repository
       puts "creating....#{local_repository}"
       Dir.mkdir(local_repository)
    end 
    begin
       envs = Dir.entries(@ec2_main.settings.get_system("REPOSITORY_LOCATION"))
    rescue
       error_message(@ec2_main,"Repository Location does not exist",$!.to_s)
    end
    super(owner, "Select Environment", :opts => DECOR_ALL, :width => 400, :height => 200)
    auto_check = FXCheckButton.new(self,"Automatically open environment at startup", :opts => ICON_BEFORE_TEXT|LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X)
    envlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    auto = "false"
    if envs != nil
       envs.each do |e|
          if e != "." and e != ".." and e != "system.properties"
             envlist.appendItem(e)
          end 
       end
       envlist.appendItem("Create New Environment")
    end   
     
    auto_check.connect(SEL_COMMAND) do
      if auto == "false"
        auto = "true"
      else
        auto = "false"
      end
      puts "auto check is "+auto
      if @curr_env != "Create New Environment" and @curr_env != ""
          @ec2_main.settings.put_system('ENVIRONMENT',@curr_env)
          @ec2_main.settings.put_system('AUTO',auto)
          @ec2_main.settings.save_system
      end
    end
     
    envlist.connect(SEL_COMMAND) do |sender, sel, data|
       selected_item = ""
       envlist.each do |item|
        selected_item = item.text if item.selected?
       end
       puts "item "+selected_item
       @curr_env = selected_item
       if selected_item != "Create New Environment"
        @ec2_main.settings.put_system('ENVIRONMENT',@curr_env)
        @ec2_main.settings.put_system('AUTO',auto)
        @ec2_main.settings.save_system
       end
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def selected
    return @curr_env
  end
  
  def error_message(owner,title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end

end