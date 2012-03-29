
require 'rubygems'
require 'fox16'

include Fox

class LOC_DeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
     @ec2_main = owner
     @delete_item = curr_item
     @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Server "+@delete_item)
     if answer == MBOX_CLICKED_YES
        folder = "loc_server"
        loc = EC2_Properties.new
        if loc != nil
           begin      
              @deleted = loc.delete(folder, @delete_item)
              if @deleted == false
                 error_message("Server Deletion failed","Server Deletion failed")
              end
           rescue
             error_message("Server Deletion failed",$!.to_s)
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