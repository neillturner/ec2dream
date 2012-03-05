
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
 
include Fox

class RDS_SecGrp_RevokeDialog < FXDialogBox

  def initialize(owner, curr_group,  curr_item, curr_item_1, curr_item_2)
    @ec2_main = owner
    @current_group = curr_group
    @deleted = false    
    owner = curr_item
    group = curr_item_1
    ip = curr_item_2
    message = ""
    if ip == nil or ip == ""
       if owner != nil and owner != ""
          message = "Confirm Revoke of Authorization for owner "+owner+ " group "+group
       else
          message = "Confirm Revoke of Authorization for group "+group
       end
    else 
       message = "Confirm Revoke of Authorization for IP Address "+ip
    end    
    answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Revoke",message )
    if answer == MBOX_CLICKED_YES
       if ip == nil or ip == ""
          revoke(owner, group)
       else
          revoke_ip(ip)
       end        
    end    
  end 
  
  def revoke_ip(ip_address)
       rds = @ec2_main.environment.rds_connection
       if rds != nil
	   params = {}
         params[:cidrip] = ip_address
         begin
           r = rds.revoke_db_security_group_ingress(@current_group, params)
           @deleted = true
         rescue
           error_message("Invalid IP Address",$!.to_s)
        end 
       end
  end
  
  def revoke(owner_id, group)
         if owner_id == nil or owner_id == ""
            id = @ec2_main.settings.get('AMAZON_ACCOUNT_ID')
            if id != nil and id != ""
               owner_id = id
            end        
         end
         rds = @ec2_main.environment.rds_connection         
         if rds != nil
           params = {}
           params[:ec2_security_group_name] = group
           params[:ec2_security_group_owner] = owner_id
           begin
             r = rds.revoke_db_security_group_ingress(@current_group, params)
             @deleted = true
           rescue
             error_message("Security Group Revoke failed",$!.to_s)
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