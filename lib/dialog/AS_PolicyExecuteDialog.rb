
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class AS_PolicyExecuteDialog < FXDialogBox

  def initialize(owner, curr_item, group_name)
     @ec2_main = owner
     @item = curr_item
     @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm execute","Confirm execute of Scaling Policy "+@item)
     if answer == MBOX_CLICKED_YES
	   begin
	      options = {}
	      options['AutoScalingGroupName'] =  group_name
              @ec2_main.environment.auto_scaling_policies.execute_policy(@item, options)
              @deleted = true
           rescue
             error_message("Scaling Policy Execution failed",$!)
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