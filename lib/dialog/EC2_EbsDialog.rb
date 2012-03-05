
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'common/EC2_ResourceTags'

include Fox

class EC2_EbsDialog < FXDialogBox

  def initialize(owner)
    puts "EbsDialog.initialize"
    @ec2_main = owner
    @curr_ebs = ""
    @curr_az = ""
    @item_name = Array.new    
    ec2 = @ec2_main.environment.connection
    if ec2 != nil
       i=0
       ec2.describe_volumes.each do |r|
         if  r[:aws_status] == "available" 
            if r[:tags] != nil
               t = EC2_ResourceTags.new(@ec2_main,r[:tags])
               n = t.nickname()
               if n != nil and n != ""
	            r[:aws_id] = n +"/"+ r[:aws_id]
               end
            end
         end   
         @item_name[i]=r[:aws_id]+"/"+r[:zone]
         i = i+1
       end
    end
       @item_name = @item_name.sort
       super(owner, "Select EBS", :opts => DECOR_ALL, :width => 400, :height => 200)
       itemlist = FXList.new(self, :opts => LIST_SINGLESELECT|LAYOUT_FILL)
       i=0
       while i < @item_name.size
          itemlist.appendItem(@item_name[i])
          i = i+1
       end 
       itemlist.connect(SEL_COMMAND) do |sender, sel, data|
         selected_item = ""
         itemlist.each do |item|
           selected_item = item.text if item.selected?
         end
         puts "item "+selected_item
         sa = selected_item.split"/"
	 if sa.size>2
	    @curr_ebs = sa[1]
	    @curr_az = sa[2]
	 else
	    @curr_ebs = sa[0]
	    @curr_az = sa[1]
    	 end          
         puts "Ebs "+@curr_ebs
         self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end

  end
  
  def selected
    return @curr_ebs
  end
  
  def availability_zone
    return @curr_az 
  end
  

end
