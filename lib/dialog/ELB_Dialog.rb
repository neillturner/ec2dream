require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class ELB_Dialog < FXDialogBox

  def initialize(owner)
    puts "ELBDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    @ec2_main.environment.elb.describe_load_balancers.each do |r|
      @item_name.push(r['LoadBalancerName'])
    end
    @item_name = @item_name.sort
    super(owner, "Select Load Balancer", :opts => DECOR_ALL, :width => 400, :height => 200)
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
      puts "ELB "+@curr_item
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  def selected
    return @curr_item
  end
end