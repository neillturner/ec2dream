require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_InstanceDialog < FXDialogBox

  def initialize(owner)
    puts "instanceDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    super(owner, "Select Instance Type", :opts => DECOR_ALL, :width => 600, :height => 300)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    itemlist.appendItem('t1.micro            (Micro 32 or 64-bit, 613 MB, up to 2 compute unit EBS only)')    
    itemlist.appendItem('m1.small            (Small 32-bit, 1.7 GB, 1 compute unit)')
    itemlist.appendItem('m1.large            (Large 64-bit, 7.5 GB, 4 compute unit)')
    itemlist.appendItem('m1.xlarge          (Extra Large 64-bit, 15 GB, 8 compute unit)')
    itemlist.appendItem('m2.2xlarge        (High Memory Extra Large 64-bit, 17.1 GB, 6.5 compute unit)')
    itemlist.appendItem('m2.4xlarge        (High Memory Double Extra Large 64-bit, 34.2 GB, 13 compute unit)')
    itemlist.appendItem('m2.4xlarge        (High Memory Quad Extra Large 64-bit, 68.4 GB, 26 compute unit)')
    itemlist.appendItem('c1.medium       (High CPU Medium 32-bit, 1.7 GB, 5 compute unit)')
    itemlist.appendItem('c1.xlarge            (High CPU Extra Large 64-bit, 7 GB, 20 compute unit)')
    itemlist.appendItem('cc1.4xlarge        (Cluster Compute Quadruple Extra Large  64-bit, 23 GB, 33.5 compute unit. 10GBit network)')
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