
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
 

include Fox

class EC2_SecGrp_RevokeDialog < FXDialogBox

  def initialize(owner, current_group, protocol, from_port, to_port, ip_address_or_group)
    @ec2_main = owner
    @deleted = false
    message = "Confirm revoke of group #{ip_address_or_group}"
    if ip_address_or_group.include? "."
       message = "Confirm revoke of #{protocol} #{from_port} #{to_port} #{ip_address_or_group}"
    end
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm",message)
    if answer == MBOX_CLICKED_YES
       if ip_address_or_group.include? "."
          revoke_ip(current_group, protocol, from_port, to_port, ip_address_or_group)
       else
          revoke(current_group, ip_address_or_group)
       end
    end
  end
  
  
  def revoke_ip(sec_group, protocol, from_port, to_port, ip_address)
       @deleted = false
       ec2 = @ec2_main.environment.connection
       if ec2 != nil
        begin
         r = ec2.revoke_security_group_IP_ingress(sec_group, from_port, to_port, protocol, ip_address)
         @deleted = true
        rescue
          error_message("Invalid IP Address",$!.to_s)
        end 
       end
  end
    
  def revoke(sec_group, group)
         @deleted = false
         ec2 = @ec2_main.environment.connection
         if ec2 != nil
          id = @ec2_main.settings.get('AMAZON_ACCOUNT_ID')
          if id == nil or id == ""
             error_message("No AMAZON_ACCOUNT_ID Setting","No AMAZON_ACCOUNT_ID specified in Settings")
          else
             begin
                r = ec2.revoke_security_group_named_ingress(sec_group, id ,group)
                @deleted = true
             rescue
                error_message("Security Group Authorization failed",$!.to_s)
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