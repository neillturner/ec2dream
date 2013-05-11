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
    @item_name = []
    title = "Select Security Group"
    super(owner, title, :opts => DECOR_ALL, :width => 300, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
    instances = Array.new
    i=0
    if @type == "ec2"
       @ec2_main.environment.security_group.all.each do |r|
           if r['vpcId'] != nil and r['vpcId'] != ""
              @item_name[i] = "#{r[:aws_group_name]} (#{r['vpcId']})"
           else     
              @item_name[i] = r[:aws_group_name]
           end   
           i = i+1
       end
    end
    @item_name = @item_name.sort_by { |x| x.downcase }
    @item_name.each do |e|
       itemlist.appendItem(e)
    end
    itemlist.connect(SEL_COMMAND) do |sender, sel, data|
       selected_item = ""
       itemlist.each do |item|
          if item.selected?
             sa = (item.text).split"("
	     if sa.size>1
	       selected_item = sa[0].rstrip
	       @vpc =sa[1][0..-2]
	     else	     
               selected_item = item.text
             end 
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
     @selected
  end
    
  def type 
    @type
  end 
    
  def sec_grp 
     @curr_item
  end
  
  def vpc
     @vpc
  end

  
end