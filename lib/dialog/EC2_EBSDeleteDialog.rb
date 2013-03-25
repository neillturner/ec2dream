
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_EBSDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Volume "+@delete_item)
    if answer == MBOX_CLICKED_YES
           if @delete_item["/"] != nil
              sa = @delete_item.split"/"
	      if sa.size>1
	         @delete_item = sa[1]
    	      end
    	   end
  	   begin
  	      @ec2_main.environment.volumes.delete_volume(@delete_item)
              #ec2.delete_volume(@delete_item)
              @deleted = true
           rescue
              error_message("Volume Deletion failed",$!)
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

