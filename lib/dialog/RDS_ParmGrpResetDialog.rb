
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class RDS_ParmGrpResetDialog < FXDialogBox

  def initialize(owner, db_parm_grp, curr_item, curr_apply_method)
    @ec2_main = owner
    @deleted = false
    parms = {}
    parms[curr_item]=curr_apply_method
     answer = FXMessageBox.question(@ec2_main.tabBook,MBOX_YES_NO,"Confirm Reset","Confirm Reset of DB Parameter #{curr_item} in DB Parameter Group #{db_parm_grp} apply #{curr_apply_method}")
     if answer == MBOX_CLICKED_YES
        rds = @ec2_main.environment.rds_connection
        if rds != nil
	   begin 
              rds.reset_db_parameter_group(db_parm_grp,parms)
              @deleted = true
           rescue
             error_message("DB Parameters Reset failed",$!.to_s)
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