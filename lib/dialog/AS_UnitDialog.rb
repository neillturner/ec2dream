require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class AS_UnitDialog < FXDialogBox

  def initialize(owner)
    puts "AS_UnitDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    @item_name[0] = "Percent"    
    @item_name[1] = "Seconds" 
    @item_name[2] = "Microseconds"
    @item_name[3] = "Milliseconds"
    @item_name[4] = "Bytes"
    @item_name[5] = "Kilobytes"
    @item_name[6] = "Megabytes"
    @item_name[7] = "Gigabytes"
    @item_name[8] = "Terabytes"
    @item_name[9] = "Bits"
    @item_name[10] = "Kilobits"
    @item_name[11] = "Megabits"
    @item_name[12] = "Gigabits"
    @item_name[13] = "Terabits"
    @item_name[14] = "Count"
    @item_name[15] = "Bytes/Second"
    @item_name[16] = "Kilobytes/Second"
    @item_name[17] = "Megabytes/Second"
    @item_name[18] = "Gigabytes/Second"
    @item_name[19] = "Terabytes/Second"
    @item_name[20] = "Bits/Second"
    @item_name[21] = "Kilobits/Second"
    @item_name[22] = "Megabits/Second"
    @item_name[23] = "Gigabits/Second"
    @item_name[24] = "Terabits/Second"
    @item_name[25] = "Count/Second"
    @item_name[26] = "None"     
    super(owner, "Select Unit", :opts => DECOR_ALL, :width => 400, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
       itemlist.appendItem(e)
    end 
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
       @curr_item = ""
       itemlist.each do |item|
          @curr_item = item.text if item.selected?
       end
       puts "item "+@curr_item
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def selected
    return @curr_item
  end  
  
end