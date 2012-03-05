require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class RDS_InstanceDialog < FXDialogBox

  def initialize(owner)
    puts "RDSinstanceDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    super(owner, "Select DBInstance Class", :opts => DECOR_ALL, :width => 400, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    itemlist.appendItem('db.m1.small')
    itemlist.appendItem('db.m1.large')
    itemlist.appendItem('db.m1.xlarge')
    itemlist.appendItem('db.m1.xlarge')
    itemlist.appendItem('db.m2.2xlarge')
    itemlist.appendItem('db.m2.4xlarge')
    
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
       selected_item = ""
       itemlist.each do |item|
          selected_item = item.text if item.selected?
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