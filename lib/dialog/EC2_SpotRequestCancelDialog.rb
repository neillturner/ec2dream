require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_SpotRequestCancelDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Cancel","Confirm Cancel of Spot Request "+@delete_item)
     if answer == MBOX_CLICKED_YES
        ec2 = @ec2_main.environment.connection
        if ec2 != nil
           if @delete_item["/"] != nil
              sa = @delete_item.split"/"
	      if sa.size>1
	         @delete_item = sa[1]
    	      end
    	   end        
	   begin 
              ec2.cancel_spot_instance_requests([@delete_item])
              @deleted = true
           rescue
             error_message("Spot Request Cancel failed",$!)
           end   
        end
     end    
  end     
 
  def deleted 
    @deleted
  end

  def success 
    @deleted
  end
  
end