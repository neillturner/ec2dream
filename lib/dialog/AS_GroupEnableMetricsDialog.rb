
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class AS_GroupEnableMetricsDialog < FXDialogBox

  def initialize(owner, curr_item)
    @ec2_main = owner
    @item = curr_item
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm enable metrics","Confirm enable 1 minute metrics of Auto Scaling Group #{@item}")
    if answer == MBOX_CLICKED_YES
      begin
        @ec2_main.environment.auto_scaling_groups.enable_metrics_collection(@item, "1Minute")
        @deleted = true
      rescue
        error_message("Auto Scaling Group Enable 1 minute Metrics failed",$!)
      end
    end
  end
  def deleted
    @deleted
  end
  def suspend
    @deleted
  end
  def success
    @deleted
  end

end
