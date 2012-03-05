
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

require 'dialog/RDS_SecGrpDialog'
require 'dialog/RDS_InstanceDialog'
require 'dialog/RDS_ParmGrpDialog'

include Fox

class RDS_InstanceModifyDialog < FXDialogBox

  def initialize(owner, instance_id)
        puts "RDSInstanceModifyDialog.initialize"
        @ec2_main = owner
        @modified = false
        @rds_server = {}
    	@sg_table = Array.new
	@kill = @ec2_main.makeIcon("kill.png")
	@kill.create
	@add = @ec2_main.makeIcon("add.png")
	@add.create
        @magnifier = @ec2_main.makeIcon("magnifier.png")
	@magnifier.create

        super(owner, "Modify DBInstance", :opts => DECOR_ALL, :width => 600, :height => 400)
        frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
 	FXLabel.new(frame1, "DBInstance Id" )
 	@rds_server['DBInstanceId'] = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
 	@rds_server['DBInstanceId'].text=instance_id
 	@rds_server['DBInstanceId'].enabled = false
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "DBSecurity Groups" )
 	@rds_server['DBSecurity_Groups'] = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_READONLY)
    	@page1a = FXHorizontalFrame.new(frame1,LAYOUT_FILL_X, :padding => 0)
    	FXLabel.new(@page1a, " ",:opts => LAYOUT_LEFT )
    	@rds_server['DBSecurity_Groups_Create_Button'] = FXButton.new(@page1a, " ",:opts => BUTTON_TOOLBAR)
	@rds_server['DBSecurity_Groups_Create_Button'].icon = @add
	@rds_server['DBSecurity_Groups_Create_Button'].tipText = "  Add DB Security Group  "
	@rds_server['DBSecurity_Groups_Create_Button'] .connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = RDS_SecGrpDialog.new(@ec2_main)
	   dialog.execute
	   sg = dialog.selected
	   if sg != nil and sg != ""
	      @sg_table.push(sg)
              load_sg_table
	   end   	
        end
        @rds_server['DBSecurity_Groups_Create_Button'] .connect(SEL_UPDATE) do |sender, sel, data|
	    sender.enabled = true
	end
	@rds_server['DBSecurity_Groups_Delete_Button'] = FXButton.new(@page1a, " ",:opts => BUTTON_TOOLBAR)
	@rds_server['DBSecurity_Groups_Delete_Button'].icon = @kill
	@rds_server['DBSecurity_Groups_Delete_Button'] .tipText = "  Delete DB Security Group  "
	@rds_server['DBSecurity_Groups_Delete_Button'].connect(SEL_COMMAND) do |sender, sel, data|
	   dialog = RDS_SecGrpDialog.new(@ec2_main)
	   dialog.execute
	   sg = dialog.selected
	   if sg != nil and sg != ""
	      @sg_table.delete(sg)
              load_sg_table
	   end 
	end
	@rds_server['DBSecurity_Groups_Delete_Button'].connect(SEL_UPDATE) do |sender, sel, data|
	   sender.enabled = true
	end

        FXLabel.new(frame1, "DBInstance Class" )
 	@rds_server['DBInstanceClass'] = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
 	@rds_server['DBInstanceClass_Button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@rds_server['DBInstanceClass_Button'].icon = @magnifier
	@rds_server['DBInstanceClass_Button'].tipText = "Select DB Instance"
	@rds_server['DBInstanceClass_Button'].connect(SEL_COMMAND) do
	   @dialog = RDS_InstanceDialog.new(@ec2_main)
	   @dialog.execute
	   type = @dialog.selected
	   if type != nil and type != ""
	      @rds_server['DBInstanceClass'].text = type
	   end   
	end
 	FXLabel.new(frame1, "Allocated Storage" )
 	@rds_server['AllocatedStorage'] = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "Master User Password" )
 	@rds_server['MasterUserPassword'] = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "Preferred Maintenance Window" )
 	@rds_server['PreferredMaintenanceWindow'] = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "DBParameter Group Name")
 	@rds_server['DBParameterGroupName'] = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
 	@rds_server['DBParameterGroupName_Button'] = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	@rds_server['DBParameterGroupName_Button'].icon = @magnifier
	@rds_server['DBParameterGroupName_Button'].tipText = "Select DB Parameter Group"
	@rds_server['DBParameterGroupName_Button'].connect(SEL_COMMAND) do
	   @dialog = RDS_ParmGrpDialog.new(@ec2_main)
	   @dialog.execute
	   it = @dialog.selected
	   if it != nil and it != ""
	      @rds_server['DBParameterGroupName'].text = it
	   end   
	end 
	FXLabel.new(frame1, "Backup Retention Period")
 	@rds_server['BackupRetentionPeriod'] = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
	FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "PreferredBackupWindow" )
	@rds_server['PreferredBackupWindow'] = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
        FXLabel.new(frame1, "" )
        FXLabel.new(frame1, "Multi AZ" )
        @rds_server['MultiAZ'] = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
        @rds_server['MultiAZ'].numVisible = 3
        @rds_server['MultiAZ'].appendItem("")      
        @rds_server['MultiAZ'].appendItem("true")	
        @rds_server['MultiAZ'].appendItem("false")
        @rds_server['MultiAZ'].setCurrentItem(0)
        @rds_server['MultiAZ'].connect(SEL_COMMAND) do
        end    
        FXLabel.new(frame1, "" )
	FXLabel.new(frame1, "Apply Immediately" )
	@rds_server['ApplyImmediately'] = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
	@rds_server['ApplyImmediately'].numVisible = 3
        @rds_server['ApplyImmediately'].appendItem("")      
	@rds_server['ApplyImmediately'].appendItem("true")	
	@rds_server['ApplyImmediately'].appendItem("false")
	@rds_server['ApplyImmediately'].setCurrentItem(0)	
 	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "Engine Version" )
 	@rds_server['EngineVersion'] = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
 	FXLabel.new(frame1, "" ) 
        FXLabel.new(frame1, "Auto Minor Version Upgrade" )
        @rds_server['AutoMinorVersionUpgrade'] = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
        @rds_server['AutoMinorVersionUpgrade'].numVisible = 3 
        @rds_server['AutoMinorVersionUpgrade'].appendItem("")     
        @rds_server['AutoMinorVersionUpgrade'].appendItem("true")	
        @rds_server['AutoMinorVersionUpgrade'].appendItem("false")
        @rds_server['AutoMinorVersionUpgrade'].setCurrentItem(0)
        @rds_server['AutoMinorVersionUpgrade'].connect(SEL_COMMAND) do
        end    
        FXLabel.new(frame1, "" )
        FXLabel.new(frame1, "Allow Major Version Upgrade" )
        @rds_server['AllowMajorVersionUpgrade'] = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
        @rds_server['AllowMajorVersionUpgrade'].numVisible = 3
        @rds_server['AllowMajorVersionUpgrade'].appendItem("")      
        @rds_server['AllowMajorVersionUpgrade'].appendItem("true")	
        @rds_server['AllowMajorVersionUpgrade'].appendItem("false")
        @rds_server['AllowMajorVersionUpgrade'].setCurrentItem(0)
        @rds_server['AllowMajorVersionUpgrade'].connect(SEL_COMMAND) do
        end    
        FXLabel.new(frame1, "" )

        FXLabel.new(frame1, "" )
        modify = FXButton.new(frame1, "   &Modify   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
        FXLabel.new(frame1, "" )
        modify.connect(SEL_COMMAND) do |sender, sel, data|
           modify_instance
           if @modified == true
              self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
           end           
        end
  end 
  
  def modify_instance
    modify_parm = {}
    if @rds_server['DBParameterGroupName'].text != nil and @rds_server['DBParameterGroupName'].text != ""
       modify_parm[:db_parameter_group] = @rds_server['DBParameterGroupName'].text
    end
    if @rds_server['DBSecurity_Groups'].text != nil and @rds_server['DBSecurity_Groups'].text != ""
        modify_parm[:db_security_groups] = @sg_table 
    end
    if @rds_server['PreferredMaintenanceWindow'].text != nil and @rds_server['PreferredMaintenanceWindow'].text != ""
        modify_parm[:preferred_maintenance_window] = @rds_server['PreferredMaintenanceWindow'].text
    end
    if @rds_server['MasterUserPassword'].text != nil and @rds_server['MasterUserPassword'].text != ""
        modify_parm[:master_user_password] = @rds_server['MasterUserPassword'].text
    end
    if @rds_server['AllocatedStorage'].text != nil and @rds_server['AllocatedStorage'].text != ""
        modify_parm[:allocated_storage] = @rds_server['AllocatedStorage'].text
    end    
    if @rds_server['DBInstanceClass'].text != nil and @rds_server['DBInstanceClass'].text != ""
        modify_parm[:instance_class] = @rds_server['DBInstanceClass'].text
    end
    if @rds_server['BackupRetentionPeriod'].text != nil and @rds_server['BackupRetentionPeriod'].text != ""
        modify_parm[:backup_retention_period] = @rds_server['BackupRetentionPeriod'].text
    end
    if @rds_server['PreferredBackupWindow'].text != nil and @rds_server['PreferredBackupWindow'].text != ""
        modify_parm[:preferred_backup_window] = @rds_server['PreferredBackupWindow'].text
    end
    if @rds_server['ApplyImmediately'].itemCurrent?(1)
       modify_parm[:apply_immediately] = "true"
    end 
    if @rds_server['ApplyImmediately'].itemCurrent?(2)
       modify_parm[:apply_immediately] = "false"
    end    
    if @rds_server['MultiAZ'].itemCurrent?(1)
       modify_parm[:multi_az] = "true"
    end 
    if @rds_server['MultiAZ'].itemCurrent?(2)
       modify_parm[:multi_az] = "false"
    end
    if @rds_server['EngineVersion'].text != nil and @rds_server['EngineVersion'].text != ""
        modify_parm[:engine_version] = @rds_server['EngineVersion'].text
    end    
    if @rds_server['AutoMinorVersionUpgrade'].itemCurrent?(1)
       modify_parm[:auto_minor_version_upgrade] = "true"
    end 
    if @rds_server['AutoMinorVersionUpgrade'].itemCurrent?(2)
       modify_parm[:auto_minor_version_upgrade] = "false"
    end    
    if @rds_server['AllowMajorVersionUpgrade'].itemCurrent?(1)
       modify_parm[:allow_major_version_upgrade] = "true"
    end 
    if @rds_server['AllowMajorVersionUpgrade'].itemCurrent?(2)
       modify_parm[:allow_major_version_upgrade] = "false"
    end        

    rds = @ec2_main.environment.rds_connection
    if rds != nil
       begin
         r = rds.modify_db_instance(@rds_server['DBInstanceId'].text, modify_parm)
         @modified = true
       rescue
         error_message("Modify DB Instance Failed",$!.to_s)
       end  
    end
  end 

  def load_sg_table
         @rds_server['DBSecurity_Groups'].text = ""
         @sg_table.each do |m|
           if m!= nil
              if @rds_server['DBSecurity_Groups'].text != ""
                 @rds_server['DBSecurity_Groups'].text = @rds_server['DBSecurity_Groups'].text + "," + m
              else
                 @rds_server['DBSecurity_Groups'].text = m
              end
   	     end 
         end   
   end

  
  def modified
     @modified
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
 
end
