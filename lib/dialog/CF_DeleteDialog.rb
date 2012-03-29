require 'rubygems'
require 'fox16'

include Fox

class CF_DeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
     @ec2_main = owner
     @delete_item = curr_item
     @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Stack "+@delete_item)
     if answer == MBOX_CLICKED_YES
        folder = "cf_templates"
        cf = EC2_Properties.new
        if cf != nil
           begin      
              @deleted = cf.delete(folder, @delete_item)
              if @deleted == false
                 error_message("Stack Deletion failed","Stack Deletion failed")
              end
           rescue
             error_message("Stack Deletion failed",$!.to_s)
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