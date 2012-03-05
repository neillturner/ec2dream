
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_AvailZoneDialog < FXDialogBox

  def initialize(owner)
    puts "AvailZoneDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    ec2 = @ec2_main.environment.connection
    if ec2 != nil
       i=0
       begin 
          ec2.describe_availability_zones.each do |r|
            @item_name[i] = r[:zone_name]
            i = i+1
          end
       rescue
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
  end
  
  def selected
    return @curr_item
  end  
  
end