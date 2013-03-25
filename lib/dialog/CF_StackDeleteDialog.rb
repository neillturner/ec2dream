
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class CF_StackDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
     @ec2_main = owner
     @delete_item = curr_item
     @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm Delete of Stack "+@delete_item)
     if answer == MBOX_CLICKED_YES   
       cf = @ec2_main.environment.cf_connection
       if cf != nil
  	   begin
             response = cf.delete_stack(@delete_item)
           rescue
             error_message("Stack Deletion failed",$!)
          end        
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