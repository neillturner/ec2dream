
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_RegionsDialog < FXDialogBox

  def initialize(owner,type)
    puts "RegionsDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    if type == "EC2"
       @item_name[0] = "https://ec2.us-east-1.amazonaws.com/ (Virgina)"
       @item_name[1] = "https://ec2.us-west-1.amazonaws.com/ (California)"
       @item_name[2] = "https://ec2.us-west-2.amazonaws.com/ (Oregon)" 
       @item_name[3] = "https://ec2.eu-west-1.amazonaws.com/ (Ireland)"
       @item_name[4] = "https://ec2.ap-southeast-1.amazonaws.com/ (Singapore)"
       @item_name[5] = "https://ec2.ap-northeast-1.amazonaws.com/ (Tokyo)"
       @item_name[6] = "https://ec2.sa-east-1.amazonaws.com/ (Sao Paulo)"
       @item_name[7] = "https://ec2.us-gov-west-1.amazonaws.com/ (US GovCloud)"
    end
    if type == "AS"
       @item_name[0] = "https://autoscaling.us-east-1.amazonaws.com/ (Virgina)"
       @item_name[1] = "https://autoscaling.us-west-1.amazonaws.com/ (California)"
       @item_name[2] = "https://autoscaling.us-west-2.amazonaws.com/ (Oregon)" 
       @item_name[3] = "https://autoscaling.eu-west-1.amazonaws.com/ (Ireland)"
       @item_name[4] = "https://autoscaling.ap-southeast-1.amazonaws.com/ (Singapore)"
       @item_name[5] = "https://autoscaling.ap-northeast-1.amazonaws.com/ (Tokyo)"
       @item_name[6] = "https://autoscaling.sa-east-1.amazonaws.com/ (Sao Paulo)"
    end    
    if type == "RDS"
       @item_name[0] = "https://rds.us-east-1.amazonaws.com/ (Virgina)"
       @item_name[1] = "https://rds.us-west-1.amazonaws.com/ (California)"
       @item_name[2] = "https://rds.us-west-2.amazonaws.com/ (Oregon)" 
       @item_name[3] = "https://rds.eu-west-1.amazonaws.com/ (Ireland)"
       @item_name[4] = "https://rds.ap-southeast-1.amazonaws.com/ (Singapore)"
       @item_name[5] = "https://rds.ap-northeast-1.amazonaws.com/ (Tokyo)"
       @item_name[6] = "https://rds.sa-east-1.amazonaws.com/ (Sao Paulo)"
    end   
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