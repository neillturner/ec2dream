
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_AvailZoneDialog < FXDialogBox

  def initialize(owner,platform="")
    puts "AvailZoneDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = []
       i=0
       @ec2_main.environment.availability_zones.all(platform).each do |r|
          @item_name[i] = r[:zone_name]
          i = i+1
       end
       @item_name = @item_name.sort
       super(owner, "Select AvailZone", :opts => DECOR_ALL, :width => 400, :height => 200)
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
         @curr_item = selected_item
         puts "AvailZone "+@curr_item
         self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end
  end
  
  def selected
    return @curr_item
  end  
  
end