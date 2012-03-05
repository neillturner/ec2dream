
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class RDS_SnapDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of DB Snapshot "+@delete_item)
     if answer == MBOX_CLICKED_YES
        rds = @ec2_main.environment.rds_connection
        if rds != nil
	   begin 
              rds.delete_db_snapshot(@delete_item)
              @deleted = true
           rescue
              error_message("DB Snapshot Deletion failed",$!.to_s)
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