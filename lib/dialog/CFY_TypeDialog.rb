require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class CFY_TypeDialog < FXDialogBox

  def initialize(owner)
    puts "CFY_TypeDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    begin
      frameworks = @ec2_main.environment.cfy_system.find_all_frameworks()
      frameworks.each do |fwk_name, fwk|
        @item_name.push(fwk_name)
      end
    rescue
      puts "ERROR: getting frameworks  #{$!}"
    end
    @item_name = @item_name.sort
    super(owner, "Select Service", :opts => DECOR_ALL, :width => 600, :height => 300)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
      itemlist.appendItem("#{e}")
    end
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
      selected_item = ""
      itemlist.each do |item|
        if item.selected?
          selected_item = item.text
        end
      end
      puts "item "+selected_item
      @curr_item = selected_item
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  def selected
    @curr_item
  end
end