
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class AS_PolicyDeleteDialog < FXDialogBox

  def initialize(owner, curr_item, group_name)
     @ec2_main = owner
     @delete_item = curr_item
     @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Scaling Policy "+@delete_item)
     if answer == MBOX_CLICKED_YES
	   begin 
              @ec2_main.environment.auto_scaling_policies.delete_policy(group_name, @delete_item)
              @deleted = true
           rescue
             error_message("Scaling Policy Deletion failed",$!)
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