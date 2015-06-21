
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class AS_LaunchConfigurationDialog < FXDialogBox

  def initialize(owner)
    puts "ASLaunchConfigurationDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = []
    i=0
    begin
      #as.describe_launch_configurations.each do |r|
      @ec2_main.environment.launch_configurations.all.each do |r|
        @item_name[i] = r[:launch_configuration_name]
        i = i+1
      end
    rescue
    end
    @item_name = @item_name.sort
    super(owner, "Select Launch Configuration", :opts => DECOR_ALL, :width => 400, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    @item_name.each do |e|
      itemlist.appendItem(e)
    end
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
      selected_item = ""
      itemlist.each do |item|
        selected_item = item.text if item.selected?
      end
      puts "item "+selected_item
      @curr_item = selected_item
      puts "Launch Configuration "+@curr_item
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  def selected
    @curr_item
  end
end
