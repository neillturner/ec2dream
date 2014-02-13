require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class GOG_AddressDialog < FXDialogBox

  def initialize(owner)
    puts "GOG_AddressDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = []
    begin 
       @item_name = @ec2_main.environment.addresses.all
    rescue
    end     
    super(owner, "Select Address", :opts => DECOR_ALL, :width => 600, :height => 300)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
       itemlist.appendItem("#{e['address']} (#{e['name']})")
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