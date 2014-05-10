
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_LaunchDialog < FXDialogBox

  def initialize(owner,type="ec2")
    @curr_env = ""
    @ec2_main = owner
    @profile_folder = "launch"
    @profile_folder = "opslaunch" if @ec2_main.settings.openstack
    envs = nil
    begin
       envs = Dir.entries(@ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder)
    rescue
       error_message("Envronment does not exist",$!)
    end
    super(owner, "Select Launch Profile", :opts => DECOR_ALL, :width => 400, :height => 200)
    envlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    auto = "false"
    if envs != nil
       envs.each do |e|
          if e != "." and e != ".."
              if e.end_with?(".properties")
                 envlist.appendItem(e[0..-12])
              end
          end
       end
    end
    envlist.connect(SEL_COMMAND) do |sender, sel, data|
       selected_item = ""
       envlist.each do |item|
        selected_item = item.text if item.selected?
       end
       puts "item "+selected_item
       @curr_env = selected_item
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end

  def selected
    return @curr_env
  end

end