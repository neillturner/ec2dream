require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class AS_PolicyDialog < FXDialogBox

  def initialize(owner,group=nil)
    puts "AS_PolicyDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = Array.new
    options = {}
    if group != nil and group != ""
      options['AutoScalingGroupName']= group
    end
    i=0
    begin
      @ec2_main.environment.auto_scaling_policies.all(options).each do |r|
        if r['PolicyARN'] != nil and r['PolicyARN'] != ""
          @item_name[i] = r['PolicyARN']
          i = i+1
        end
      end
    rescue
    end
    super(owner, "Select Policy ARN", :opts => DECOR_ALL, :width => 600, :height => 300)
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