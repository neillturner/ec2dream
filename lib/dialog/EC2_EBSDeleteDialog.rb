
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_EBSDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of EBS Volume "+@delete_item)
    if answer == MBOX_CLICKED_YES
        ec2 = @ec2_main.environment.connection
        if ec2 != nil
           if @delete_item["/"] != nil
              sa = @delete_item.split"/"
	      if sa.size>1
	         @delete_item = sa[1]
    	      end
    	   end
  	   begin 
              ec2.delete_volume(@delete_item)
              @deleted = true
           rescue
              error_message("EBS Volume Deletion failed",$!.to_s)
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

