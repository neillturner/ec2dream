
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class AS_TriggerDeleteDialog < FXDialogBox

  def initialize(owner, curr_item, as_group)
     @ec2_main = owner
     @delete_item = curr_item
     @as_name = as_group
     @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Trigger "+@delete_item)
     if answer == MBOX_CLICKED_YES
        as = @ec2_main.environment.as_connection
        if as != nil
	   begin 
              as.delete_trigger(@delete_item, @as_name)
              @deleted = true
           rescue
             error_message("Trigger Deletion failed",$!.to_s)
           end   
        end
     end    
  end     
 
  def deleted 
    @deleted
  end

  def error_message(title,message)
    FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
end