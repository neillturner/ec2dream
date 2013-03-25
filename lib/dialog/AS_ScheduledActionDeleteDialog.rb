
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class AS_ScheduledActionDeleteDialog < FXDialogBox

  def initialize(owner, curr_item, group_name)
     @ec2_main = owner
     @delete_item = curr_item
     @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Scheduled Action "+@delete_item)
     if answer == MBOX_CLICKED_YES
	   begin 
              @ec2_main.environment.scheduled_actions.delete_scheduled_action(group_name, @delete_item)
              @deleted = true
           rescue
             error_message("Scheduled Action Deletion failed",$!)
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