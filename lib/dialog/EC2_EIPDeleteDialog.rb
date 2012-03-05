
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_EIPDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm Release of Elastic IP "+@delete_item)
     if answer == MBOX_CLICKED_YES
        ec2 = @ec2_main.environment.connection
        if ec2 != nil
  	   begin 
              ec2.release_address({:public_ip => @delete_item})
              @deleted = true
           rescue
             error_message("Release of Elastic IP failed",$!.to_s)
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