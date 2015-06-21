
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_ImageDeRegisterDialog < FXDialogBox

  def initialize(owner,image)
    @ec2_main = owner
    sa = (image).split("/")
    sel_image = image
    if sa.size>1
      sel_image = sa[1].rstrip
    end
    @deleted = false
    if sel_image != "** Not Found **"
      answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm","Confirm Deregister of Image "+sel_image)
      if answer == MBOX_CLICKED_YES
        begin
          @ec2_main.environment.images.deregister_image(sel_image)
          @deleted = true
        rescue
          error_message("DeRegister of Image failed",$!)
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
