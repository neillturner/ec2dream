
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
 

include Fox

class EC2_EIPDisassociateDialog < FXDialogBox

  def initialize(owner,dis_eip)
    @ec2_main = owner
    ec2 = @ec2_main.environment.connection
    dis_server = "" 
    @deleted = false
    if dis_eip["/"] != nil
       sa = (dis_eip).split"/"
       if sa.size>2
          dis_eip = (sa[2]).strip
          dis_server = sa[0]+"/"+sa[1]
       end
    end      
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm","Confirm Disassociate of Elastic IP "+dis_eip+" from Server "+dis_server)
    if answer == MBOX_CLICKED_YES
        ec2 = @ec2_main.environment.connection
        if ec2 != nil
  	   begin 
              ec2.disassociate_address({:public_ip=> dis_eip})
              @deleted = true
           rescue
             error_message("Disassociate of Elastic IP failed",$!.to_s)
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