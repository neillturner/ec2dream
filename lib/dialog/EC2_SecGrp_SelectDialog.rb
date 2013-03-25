require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_SecGrp_SelectDialog < FXDialogBox

  def initialize(owner, type="ec2")
    puts "SecGrp_SelectDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @selected = false
    @type = type
    title = "Select Security Group"
    super(owner, title, :opts => DECOR_ALL, :width => 300, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    instances = Array.new
    i=0
    if @type == "ec2"
       @ec2_main.environment.security_group.all.each do |r|
           instances[i] = r[:aws_group_name]
           i = i+1
       end
    end
    instances = instances.sort_by { |x| x.downcase }
    instances.each do |inst|
       itemlist.appendItem(inst)
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
       puts "SecGrp "+@curr_item
       @selected = true
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  
  def selected
      return @selected
  end
    
  def type 
      return @type
  end 
    
  def sec_grp 
     return  @curr_item
  end 
  
  
end