require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class GOG_NetworkDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Network "+@delete_item)
    if answer == MBOX_CLICKED_YES
   	   begin
  	      @ec2_main.environment.vpc.delete_network(@delete_item)
          @deleted = true
       rescue
          error_message("Network Deletion failed",$!)
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

