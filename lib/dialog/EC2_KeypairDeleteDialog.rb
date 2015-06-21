
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_KeypairDeleteDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm Delete of Key Pair "+@delete_item)
    if answer == MBOX_CLICKED_YES
      begin
        @ec2_main.environment.keypairs.delete(@delete_item)
        @deleted = true
      rescue
        error_message("Delete of Key Pair failed",$!)
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
