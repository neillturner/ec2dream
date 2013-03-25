require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'tzinfo'

include Fox

class EC2_TimezoneDialog < FXDialogBox

  def initialize(owner)
    puts "TimezoneDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = TZInfo::Timezone.all()
    i=0
    super(owner, "Select Timezone", :opts => DECOR_ALL, :width => 400, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
       e = e.to_s
       e = e.sub(" - ","/")
       itemlist.appendItem(e)
    end 
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
       selected_item = ""
       itemlist.each do |item|
          selected_item = item.text if item.selected?
       end
       puts "item "+selected_item
       @curr_item = selected_item
       puts "Timezone "+@curr_item
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def selected
    return @curr_item
  end  
  
end