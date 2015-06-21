
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class AS_AlarmDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of Cloud Watch Alarm "+@delete_item)
    if answer == MBOX_CLICKED_YES
      begin
        @ec2_main.environment.cloud_watch.delete_alarms([@delete_item])
        @deleted = true
      rescue
        error_message("Cloud Watch Alarm Deletion failed",$!)
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
