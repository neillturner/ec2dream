require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_ServerDialog < FXDialogBox

  def initialize(owner)
    puts "serverDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    super(owner, "Select Server", :opts => DECOR_ALL, :width => 600, :height => 300)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    instances = @ec2_main.serverCache.instance_names
    instances.each do |inst|
       itemlist.appendItem(inst)
    end
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
       selected_item = ""
       itemlist.each do |item|
          if item.selected?
              selected_item = item.text
          end
       end
       puts "item "+selected_item
       @curr_item = selected_item
       puts "server "+@curr_item
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def selected
    return @curr_item
  end  
  
end