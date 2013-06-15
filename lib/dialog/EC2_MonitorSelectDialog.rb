require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'date'
require 'dialog/EC2_MonitorDialog'

include Fox

class EC2_MonitorSelectDialog < FXDialogBox

  def initialize(owner,dimension_value,dimension_type,group_name=nil,platform="")
    puts "EC2_MonitorSelectDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = []
    @item_name.push("Last Hour")
    @item_name.push("Last 3 Hours")
    @item_name.push("Last 12 Hours")
    @item_name.push("Last 24 Hours")
    @item_name.push("Today")
    @item_name.push("Yesterday")
    @item_name.push("Last Fortnight")
    d = Date.today()
    d = d-2
    i = 0
    while i < 12  
       @item_name.push((d.strftime("%a %b %d %Y")))
       d = d-1
       i = i+1
    end 	
    super(owner, "Select Monitoring Period", :opts => DECOR_ALL, :width => 300, :height => 200)
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
       if dimension_type == "AutoScalingGroupName"
           cloudwatch_data = File.read("#{ENV['EC2DREAM_HOME']}/lib/amazon_cloudwatch_as.json")
       elsif dimension_type == "LoadBalancerName"
           cloudwatch_data = File.read("#{ENV['EC2DREAM_HOME']}/lib/amazon_cloudwatch_elb.json") 
       elsif dimension_type == "VolumeId"
           cloudwatch_data = File.read("#{ENV['EC2DREAM_HOME']}/lib/amazon_cloudwatch_ebs.json")     
       else
          if platform == "windows"
             cloudwatch_data = File.read("#{ENV['EC2DREAM_HOME']}/lib/amazon_windows_cloudwatch.json")
          else
       	     cloudwatch_data = File.read("#{ENV['EC2DREAM_HOME']}/lib/amazon_cloudwatch.json")
       	  end
       end	  
       amazon_cloudwatch = JSON.parse(cloudwatch_data)
       #Thread.new {
          dialog = EC2_MonitorDialog.new(@ec2_main,dimension_value,group_name,@curr_item,amazon_cloudwatch,dimension_type)
          dialog.execute
       #}   
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def selected
    return @curr_item
  end  
  
end