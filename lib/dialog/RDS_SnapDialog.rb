
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class RDS_SnapDialog < FXDialogBox

  def initialize(owner,db_instance)
    puts "RDSSnapDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    rds = @ec2_main.environment.rds_connection
    if rds != nil
       i=0
       begin
          params = {}
          params[:instance_aws_id]=db_instance
          rds.describe_db_snapshots(params).each do |r|
             if r[:status] == "available"
                @item_name[i] = r[:aws_id]
                i = i+1
             end   
          end
       rescue
          error_message("Describe DB Snapshots Failed",$!.to_s)
       end
       @item_name = @item_name.sort
       super(owner, "Select DBSnapshot for DBInstance", :opts => DECOR_ALL, :width => 400, :height => 200)
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
          puts "DBSnap "+@curr_item
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