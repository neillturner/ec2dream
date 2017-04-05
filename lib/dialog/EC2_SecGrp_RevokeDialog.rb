
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_SecGrp_RevokeDialog < FXDialogBox

  def initialize(owner, current_group, protocol, from_port, to_port, ip_address_or_group, rule_id=0, current_group_id=nil, auth_group_id=nil, type='ingress' )
    @ec2_main = owner
    @deleted = false
    message = "Confirm revoke of #{type} #{protocol} #{from_port} #{to_port} #{ip_address_or_group}"
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm",message)
    if answer == MBOX_CLICKED_YES
      revoke_ip(current_group, protocol, from_port, to_port, ip_address_or_group, rule_id, current_group_id, auth_group_id, type)
    end
  end
  def revoke_ip(sec_group, protocol, from_port, to_port, ip_address, rule_id, group_id, auth_group_id, type)
    @deleted = false
    if  !@ec2_main.settings.openstack
      begin
        if ip_address.include? "."
          r =  @ec2_main.environment.security_group.delete_security_group_rule(sec_group, protocol, from_port, to_port, ip_address, nil, nil, group_id, nil, type)
        else
          r =  @ec2_main.environment.security_group.delete_security_group_rule(sec_group, protocol, from_port, to_port, nil, nil, ip_address, group_id, auth_group_id, type )
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

  def deleted
    @deleted
  end

  def success
    @deleted
  end
end