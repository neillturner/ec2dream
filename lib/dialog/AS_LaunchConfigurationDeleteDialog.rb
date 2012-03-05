
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class AS_LaunchConfigurationDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
     @ec2_main = owner
     @delete_item = curr_item
     @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Launch Configuration "+@delete_item)
     if answer == MBOX_CLICKED_YES
        as = @ec2_main.environment.as_connection
        if as != nil
	   begin 
              as.delete_launch_configuration(@delete_item)
              @deleted = true
           rescue
             error_message("Launch Configuration Deletion failed",$!.to_s)
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