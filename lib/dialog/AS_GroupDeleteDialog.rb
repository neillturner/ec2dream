
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class AS_GroupDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
     @ec2_main = owner
     @delete_item = curr_item
     @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Auto Scaling Group "+@delete_item)
     if answer == MBOX_CLICKED_YES
        as = @ec2_main.environment.as_connection
        if as != nil
	   begin 
              as.delete_auto_scaling_group(@delete_item)
              @deleted = true
           rescue
             error_message("Auto Scaling Group Deletion failed",$!.to_s)
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