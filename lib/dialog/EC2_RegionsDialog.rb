require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_RegionsDialog < FXDialogBox

  def initialize(owner,type,platform="")
    puts "RegionsDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = @ec2_main.environment.regions.all(type,platform) 
    super(owner, "Select Region", :opts => DECOR_ALL, :width => 400, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
       itemlist.appendItem(e)
    end 
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
       selected_item = ""
       itemlist.each do |item|
          selected_item = item.text if item.selected?
       end
       puts "item "+selected_item
       sa = selected_item.split("(")
       if sa.length>1
          @curr_item = sa[0].strip
       end  
       puts "item "+@curr_item
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def selected
    return @curr_item
  end  
  
end