require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class AS_MetricDialog < FXDialogBox

  def initialize(owner,parm)
    puts "AS_MetricDialog.initialize"
    @ec2_main = owner
    options = {}
    options['Namespace']=parm
    @curr_item = ""
    @item_name = Array.new
    i=0
    begin 
       @ec2_main.environment.cloud_watch.list_metrics(options).each do |r|
          @item_name[i] = r['MetricName']
          i = i+1
       end
    rescue
    end     
    super(owner, "Select Metric for Namespace #{parm}", :opts => DECOR_ALL, :width => 600, :height => 300)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
       itemlist.appendItem(e)
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
       puts "instance "+@curr_item
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def selected
    return @curr_item
  end  
  
end