
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
 

include Fox

class EC2_EBSDetachDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    detach_ebs = curr_item
    ebs_server = ""
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Detach","Confirm Detach of EBS Volume "+detach_ebs )
    if answer == MBOX_CLICKED_YES
        ec2 = @ec2_main.environment.connection
        if ec2 != nil
           if detach_ebs["/"] != nil
              sa = (detach_ebs).split"/"
              if sa.size>1
                 detach_ebs = (sa[1]).lstrip
              end
           end        
  	   begin 
              ec2.detach_volume(detach_ebs)
              @deleted = true
           rescue
             error_message("EBS Volume Detach failed",$!.to_s)
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