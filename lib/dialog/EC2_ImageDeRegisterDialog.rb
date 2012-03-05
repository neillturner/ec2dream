
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

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
    ec2 = @ec2_main.environment.connection
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm","Confirm Deregister of Image "+sel_image)
    if answer == MBOX_CLICKED_YES
        ec2 = @ec2_main.environment.connection
        if ec2 != nil
  	   begin
              ec2.deregister_image(sel_image)
              @deleted = true
           rescue
             error_message("DeRegister of Image failed",$!.to_s)
           end
        else
      	   puts "***Error: No EC2 Connection"
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