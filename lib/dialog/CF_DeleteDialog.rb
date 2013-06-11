require 'rubygems'
require 'fox16'
require 'common/error_message'

include Fox

class CF_DeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
     @ec2_main = owner
     @delete_item = curr_item
     @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Configuration #{@delete_item}, The template file will not be deleted" )
     if answer == MBOX_CLICKED_YES
        folder = "cf_templates"
        cf = EC2_Properties.new
        if cf != nil
           begin      
              @deleted = cf.delete(folder, @delete_item)
              if @deleted == false
                 error_message("Configuration Deletion failed","Configuration Deletion failed")
              end
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