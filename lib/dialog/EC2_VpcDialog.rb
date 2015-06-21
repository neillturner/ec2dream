
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_VpcDialog < FXDialogBox

  def initialize(owner)
    puts "VpcDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    i=0
    @ec2_main.environment.vpc.describe_vpcs.each do |r|
      @item_name[i] = r['vpcId']
      i = i+1
    end
    @item_name = @item_name.sort
    super(owner, "Select VPC", :opts => DECOR_ALL, :width => 400, :height => 200)
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
      puts "Vpc "+@curr_item
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  def selected
    return @curr_item
  end
end