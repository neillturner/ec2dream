require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_InstanceDialog < FXDialogBox

  def initialize(owner)
    puts "instanceDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    begin
      @item_name = @ec2_main.environment.flavors.all
    rescue
    end
    super(owner, "Select Instance Type", :opts => DECOR_ALL, :width => 600, :height => 300)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
      itemlist.appendItem(e)
    end
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
      selected_item = ""
      itemlist.each do |item|
        if item.selected?
          sa=(item.text).split('(')
          selected_item = sa[0].strip
        end
      end
      puts "item "+selected_item
      @curr_item = selected_item
      puts "instance "+@curr_item
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  def selected
    return @curr_item
  end
end