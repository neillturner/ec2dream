
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class RDS_SecGrpDialog < FXDialogBox

  def initialize(owner)
    puts "RDSSecGrpDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new    
    rds = @ec2_main.environment.rds_connection
    if rds != nil
       i=0
       begin
          rds.describe_db_security_groups.each do |r|
             @item_name[i] = r[:name]
             i = i+1
          end
       rescue
       end
       @item_name = @item_name.sort
       super(owner, "Select DB Security Group", :opts => DECOR_ALL, :width => 400, :height => 200)
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
          self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end
    end
  end
  
  def selected
    return @curr_item
  end  
  
end