require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class CFY_LaunchDialog < FXDialogBox

  def initialize(owner)
    @curr_item = ""
    @ec2_main = owner
    items = nil
    @profile_folder = "launch"
    super(owner, "Select Launch", :opts => DECOR_ALL, :width => 400, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
       selected_item = ""
       itemlist.each do |item|
        selected_item = item.text if item.selected?
       end
       puts "item "+selected_item
       @curr_item = selected_item
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    begin
       items = Dir.entries(@ec2_main.settings.get_system('ENV_PATH')+"/"+@profile_folder)
    rescue
       error_message("Repository Location does not exist",$!)
    end    
    if items != nil
       items.each do |e|
          e = e.to_s
          if e != "." and e != ".." and e != ".properties"
             sa = e.split"."
	     if sa.size>1 and sa[1] == "properties"
                itemlist.appendItem(sa[0])
             end
          end 
       end
    end
    itemlist.appendItem("Create New Launch")
  end
  
  def selected
    return @curr_item
  end
  
end