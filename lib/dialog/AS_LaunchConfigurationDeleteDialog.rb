
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class AS_LaunchConfigurationDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
     @ec2_main = owner
     @delete_item = curr_item
     @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Launch Configuration "+@delete_item)
     if answer == MBOX_CLICKED_YES
	   begin 
              @ec2_main.environment.launch_configurations.delete_launch_configuration(@delete_item)
              @deleted = true
           rescue
             error_message("Launch Configuration Deletion failed",$!)
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