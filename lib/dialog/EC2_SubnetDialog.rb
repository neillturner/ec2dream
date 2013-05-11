
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_SubnetDialog < FXDialogBox

  def initialize(owner)
    puts "SubnetDialog.initialize"
    @ec2_main = owner
    @curr_item = ""
    @item_name = []    
    i=0
    @ec2_main.environment.vpc.describe_subnets.each do |r|
       ta = r['tagSet']
       nickname = nil
       if ta.size>0
           t = EC2_ResourceTags.new(@ec2_main,ta,nil)
           nickname = t.nickname
       end
       if nickname != nil and nickname != ""
          @item_name[i] = "#{r['subnetId']} (#{nickname}/#{r['cidrBlock']} - #{r['availabilityZone']})"
       else	
          @item_name[i] = "#{r['subnetId']} (#{r['cidrBlock']} - #{r['availabilityZone']})"
       end
       i = i+1
    end
    @item_name = @item_name.sort
    super(owner, "Select Subnet", :opts => DECOR_ALL, :width => 400, :height => 200)
    itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
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
	     else	     
               selected_item = item.text
             end  
          end
       end
       puts "item "+selected_item
       @curr_item = selected_item
       puts "subnet "+@curr_item
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
     end
  end
  
  def selected
    return @curr_item
  end  
  
end