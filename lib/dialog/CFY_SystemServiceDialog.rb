
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class CFY_SystemServiceDialog < FXDialogBox

  def initialize(owner)
    puts "CFY_SystemServiceDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    @item_name=@ec2_main.environment.cfy_service.find_available_system_services
    @item_name = @item_name.sort
    super(owner, "Select System Service", :opts => DECOR_ALL, :width => 400, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
      itemlist.appendItem("#{e[1]} (#{e[0]})")
    end
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
      selected_item = ""
      itemlist.each do |item|
        if item.selected?
          sa =  item.text.split('(')
          selected_item = sa[0].strip
        end
      end
      puts "item "+selected_item
      @curr_item = selected_item
      puts "SystemService "+@curr_item
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  def selected
    @curr_item
  end
end