require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class ELB_PolicyDeleteDialog < FXDialogBox

  def initialize(owner, lb_name, curr_item)
    @ec2_main = owner
    @delete_item = curr_item
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm delete","Confirm delete of ELB Policy "+@delete_item)
    if answer == MBOX_CLICKED_YES
      begin
        @ec2_main.environment.elb.delete_load_balancer_policy(lb_name, @delete_item)
        @deleted = true
      rescue
        error_message("ELB Policy Deletion failed",$!)
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