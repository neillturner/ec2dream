
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_EBSDetachDialog < FXDialogBox

  def initialize(owner, curr_item, curr_instance="")
    @ec2_main = owner
    detach_ebs = curr_item
    instance_id = ""
    if curr_instance != nil
       instance_id = curr_instance
    end
    ebs_server = ""
    @deleted = false
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Detach","Confirm Detach of Volume #{detach_ebs} from instance #{instance_id}")
    if answer == MBOX_CLICKED_YES
           if detach_ebs["/"] != nil
              sa = (detach_ebs).split"/"
              if sa.size>1
                 detach_ebs = (sa[1]).lstrip
              end
           end
           if instance_id["/"] != nil
              sa = (instance_id).split"/"
              if sa.size>1
                 instance_id = (sa[1]).lstrip
              end
           end
  	   begin
              #ec2.detach_volume(detach_ebs)
              @ec2_main.environment.volumes.detach_volume(detach_ebs,instance_id)
              @deleted = true
           rescue
             error_message("Volume Detach failed",$!)
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