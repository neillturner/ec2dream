require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class GOG_DiskDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Disk "+@delete_item)
    if answer == MBOX_CLICKED_YES
   	   begin
  	      @ec2_main.environment.volumes.delete_disk(@delete_item, $google_zone)
          @deleted = true
       rescue
          error_message("Disk Deletion failed",$!)
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

