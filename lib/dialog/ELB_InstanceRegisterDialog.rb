require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class ELB_InstanceRegisterDialog < FXDialogBox

  def initialize(owner, instance_table)
    puts "InstanceRegisterDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = @ec2_main.serverCache.instance_running_names_all
    instance_table.each do |e|
      @item_name.each_index do |i|
        if @item_name[i].index(e) != nil
          @item_name[i] = nil
        end
      end
    end
    super(owner, "Select Instance", :opts => DECOR_ALL, :width => 400, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
      if e != nil
        itemlist.appendItem(e)
      end
    end
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
      selected_item = ""
      itemlist.each do |item|
        selected_item = item.text if item.selected?
      end
      puts "item "+selected_item
      sa = selected_item.split("/")
      if sa.size>1
        @curr_item = sa[1]
      else
        @curr_item = sa[0]
      end
      puts "InstanceRegister "+@curr_item
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  def selected
    return @curr_item
  end
end