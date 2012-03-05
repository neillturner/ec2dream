
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class ELB_PolicySetDialog < FXDialogBox

  def initialize(owner, policy_table)
    puts "PolicySetDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = policy_table
    super(owner, "Set Policy", :opts => DECOR_ALL, :width => 400, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
       itemlist.appendItem(e[:policy_name])
    end 
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
       selected_item = ""
       itemlist.each do |item|
          selected_item = item.text if item.selected?
       end
       puts "item "+selected_item
       @curr_item = selected_item
       puts "PolicySet "+@curr_item
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def selected
    return @curr_item
  end  
  
end