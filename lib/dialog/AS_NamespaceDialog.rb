require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class AS_NamespaceDialog < FXDialogBox

  def initialize(owner)
    puts "AS_NamespaceDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    @item_name[0] = "AWS/EC2"
    @item_name[1] = "AWS/ELB"  
    @item_name[2] = "AWS/Billing"
    @item_name[3] = "AWS/DynamoDB"
    @item_name[4] = "AWS/EBS"
    @item_name[5] = "AWS/EMR"
    @item_name[6] = "AWS/RDS"
    @item_name[7] = "AWS/SNS"
    @item_name[8] = "AWS/SQS"
    @item_name[9] = "AWS/StorageGateway"
    @item_name[10] = "AWS/AutoScaling"
  
    super(owner, "Select Namespace", :opts => DECOR_ALL, :width => 400, :height => 200)
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