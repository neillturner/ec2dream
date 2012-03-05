require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class AS_TriggerFieldsDialog < FXDialogBox

  def initialize(owner,type)
    puts "TriggerSelectDialog.initialize"
    @ec2_main = owner
    measures = ["CPUUtilization","NetworkIn","NetworkOut","DiskReadOps","DiskWriteOps","DiskReadBytes","DiskWriteBytes"]
    statistics = ["Minimum","Maximum","Average"]
    units = ["None","Seconds","Percent","Bytes","Bits","Count","Bytes/Second","Bits/Second","Count/Second"]
        
   @curr_item = ""
    super(owner, "Select #{type}", :opts => DECOR_ALL, :width => 600, :height => 300)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    case type 
     when "Measure"
        measures.each do |item|
          itemlist.appendItem(item)
        end
     when "Statistic"
        statistics.each do |item|
          itemlist.appendItem(item)
        end
     when "Unit"
        units.each do |item|
          itemlist.appendItem(item)
        end
    end 
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
       selected_item = ""
       itemlist.each do |item|
          selected_item = item.text if item.selected?
       end
       puts "item "+selected_item
       @curr_item = selected_item
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def selected
    return @curr_item
  end  
  
end