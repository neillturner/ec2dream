require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_PlatformsDialog < FXDialogBox

  def initialize(owner)
    puts "PlatformsDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    @item_name[0] = "amazon"
    @item_name[1] = "google"
    @item_name[2] = "openstack"
    @item_name[3] = "openstack_hp"
    @item_name[4] = "openstack_rackspace"
    @item_name[5] = "servers"
#    @item_name[6] = "cloudstack"
#    @item_name[7] = "cloudfoundry"
#    @item_name[8] = "eucalyptus"
    super(owner, "Select Platform", :opts => DECOR_ALL, :width => 400, :height => 200)
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