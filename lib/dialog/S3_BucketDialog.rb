
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class S3_BucketDialog < FXDialogBox

  def initialize(owner)
    puts "S3BucketDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new    
    s3 = @ec2_main.environment.s3_connection
    if s3 != nil
       @item_name = s3.buckets.map{|b| b.name}
       super(owner, "Select S3 Bucket", :opts => DECOR_ALL, :width => 400, :height => 200)
       itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
       i=0
       while i < @item_name.size
          itemlist.appendItem(@item_name[i])
          i = i+1
       end
       itemlist.appendItem("Create New Bucket")
       itemlist.connect(SEL_COMMAND) do |sender, sel, data|
         selected_item = ""
         itemlist.each do |item|
           selected_item = item.text if item.selected?
         end
         puts "item "+selected_item
         @curr_item = selected_item
         puts "s3bucket "+@curr_item
         self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end
    end
  end
  
  def selected
    return @curr_item
  end
  

  def error_message(title,message)
    FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
end