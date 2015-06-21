
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class CFY_InstancesEditDialog < FXDialogBox

  def initialize(owner, name, curr_item)
    @ec2_main = owner
    @save_item = curr_item
    @saved = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm instances","Confirm setting Instances to #{@save_item} for #{name} App")
    if answer == MBOX_CLICKED_YES
      begin
        @ec2_main.environment.cfy_app.set_instances(name,@save_item)
        @saved = true
      rescue
        error_message("Setting Instances failed",$!)
      end
    end
  end
  def saved
    @saved
  end
  def success
    @saved
  end
end
