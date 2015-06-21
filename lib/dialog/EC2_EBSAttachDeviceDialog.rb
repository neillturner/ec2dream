
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_EBSAttachDeviceDialog < FXDialogBox

  def initialize(owner)
    puts "EBSAttachDeviceDialog.initialize"
    @ec2_main = owner
    @curr_device = ""
    super(owner, "Select Device", :opts => DECOR_ALL, :width => 200, :height => 200)
    devicelist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    devicelist.appendItem("/dev/sdf");
    devicelist.appendItem("/dev/sdg");
    devicelist.appendItem("/dev/sdh");
    devicelist.appendItem("/dev/sdi");
    devicelist.appendItem("/dev/sdj");
    devicelist.appendItem("/dev/sdk");
    devicelist.appendItem("/dev/sdl");
    devicelist.appendItem("windows xvdf");
    devicelist.appendItem("windows xvdg");
    devicelist.appendItem("windows xvdh");
    devicelist.appendItem("windows xvdi");
    devicelist.appendItem("windows xvdj");
    devicelist.appendItem("windows xvdk");
    devicelist.appendItem("windows xvdl");
    devicelist.connect(SEL_COMMAND) do |sender, sel, data|
      selected_item = ""
      devicelist.each do |item|
        selected_item = item.text if item.selected?
      end
      puts "item "+selected_item
      @curr_device = selected_item
      puts "device "+@curr_device
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  def selected
    return @curr_device
  end
end