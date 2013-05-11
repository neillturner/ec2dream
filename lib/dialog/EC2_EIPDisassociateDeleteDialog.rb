
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message' 

include Fox

class EC2_EIPDisassociateDeleteDialog < FXDialogBox

  def initialize(owner,dis_eip,dis_server, association_id=nil)
     @ec2_main = owner
    server_instance = dis_server
    @deleted = false
    if dis_server["/"] != nil
       sa = (dis_server).split"/"
       if sa.size>1
          server_instance = sa[1]
       end
    end      
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm","Confirm Disassociate of IP Address "+dis_eip+" from Server "+dis_server)
    if answer == MBOX_CLICKED_YES
  	   begin 
              @ec2_main.environment.addresses.disassociate(server_instance,  dis_eip, association_id )
              @deleted = true
           rescue
              error_message("Disassociate of IP Address failed",$!)
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