require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class AS_GroupDialog < FXDialogBox

  def initialize(owner,group=nil)
    puts "AS_GroupDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    @ec2_main.environment.auto_scaling_groups.all.each do |r|
      @item_name.push(r[:auto_scaling_group_name])
    end
    super(owner, "Select AutoScaling Group", :opts => DECOR_ALL, :width => 400, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
      itemlist.appendItem(e)
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
      puts "instance "+@curr_item
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  def selected
    return @curr_item
  end
end
