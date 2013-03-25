
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message' 

include Fox

class EC2_SecGrp_RevokeDialog < FXDialogBox

  def initialize(owner, current_group, protocol, from_port, to_port, ip_address_or_group, rule_id=0)
    @ec2_main = owner
    @deleted = false
    #message = "Confirm revoke of group #{ip_address_or_group}"
    #if ip_address_or_group.include? "."
       message = "Confirm revoke of #{protocol} #{from_port} #{to_port} #{ip_address_or_group}"
    #end
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm",message)
    if answer == MBOX_CLICKED_YES
       #if ip_address_or_group.include? "."
          revoke_ip(current_group, protocol, from_port, to_port, ip_address_or_group, rule_id)
       #else
       #   revoke(current_group, ip_address_or_group, rule_id)
       #end
    end
  end
  
  
  def revoke_ip(sec_group, protocol, from_port, to_port, ip_address, rule_id)
          @deleted = false
          if  !@ec2_main.settings.openstack 
             begin
               if ip_address.include? "."
                  r =  @ec2_main.environment.security_group.delete_security_group_rule(sec_group, protocol, from_port, to_port, ip_address, rule_id=nil, nil)
               else
                  r =  @ec2_main.environment.security_group.delete_security_group_rule(sec_group, protocol, from_port, to_port, nil, rule_id=nil, ip_address)
               end
               @deleted = true
             rescue
               error_message("Invalid IP Address",$!)
             end
          else
             begin
               @ec2_main.environment.security_group.delete_security_group_rule(nil,nil,nil,nil,nil,rule_id,nil)
               @deleted = true
             rescue
               error_message("Invalid IP Address",$!)
             end     
          end
   end
    
  def revoke(sec_group, group, rule_id)
          @deleted = false
          id = @ec2_main.settings.get('AMAZON_ACCOUNT_ID')
          if id == nil or id == ""
             error_message("No AMAZON_ACCOUNT_ID Setting","No ACCOUNT_ID specified in Settings")
          else
             begin
                r =  @ec2_main.environment.security_group.revoke_security_group_named_ingress(sec_group, id ,group, rule_id)
                @deleted = true
             rescue
                error_message("Security Group Authorization failed",$!)
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