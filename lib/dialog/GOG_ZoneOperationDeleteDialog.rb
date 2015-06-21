require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class GOG_ZoneOperationDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Zone Operation "+@delete_item)
    if answer == MBOX_CLICKED_YES
      begin
        @ec2_main.environment.servers.delete_zoneoperation($google_zone,@delete_item)
        @deleted = true
      rescue
        error_message("Zone Operation Deletion failed",$!)
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

