
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'dialog/EC2_AvailZoneDialog'
require 'dialog/RDS_InstanceDialog'

include Fox

class RDS_RestoreTimeDialog < FXDialogBox

  def initialize(owner, instance_id = nil , params = {})
    puts "RDSRestoreTimeDialog.initialize"
    @ec2_main = owner
    @created = false
    @target = nil
    super(owner, "Restore DB Instance to Point in Time", :opts => DECOR_ALL, :width => 450, :height => 300)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    
    FXLabel.new(frame1, "Source DB Instance id" )
    source_db_instance_id = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Target DB Instance id" )
    target_db_instance_id = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "DB Instance Class" )
    db_instance_class = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    db_instance_class_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)    
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    db_instance_class_button.icon = @magnifier
    db_instance_class_button.tipText = "Select DBInstance Class"
    db_instance_class_button.connect(SEL_COMMAND) do
	   dialog = RDS_InstanceDialog.new(@ec2_main)
	   dialog.execute
	   type = dialog.selected
	   if type != nil and type != ""
	       db_instance_class.text = type
	   end   
    end
    FXLabel.new(frame1, "Port" )
    port = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Availability  Zone" )
    availability_zone = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    availability_zone_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    availability_zone_button.icon = @magnifier
    availability_zone_button.tipText = "Select Availability Zone"    
    availability_zone_button.connect(SEL_COMMAND) do
       dialog = EC2_AvailZoneDialog.new(@ec2_main)
       dialog.execute
       az = dialog.selected
       if az != nil and az != ""
          availability_zone.text = az
       end   
    end
    FXLabel.new(frame1, "Multi AZ" )
    multi_az = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    multi_az.numVisible = 2
    multi_az.appendItem("true")	
    multi_az.appendItem("false")
    multi_az.setCurrentItem(1)
    multi_az.connect(SEL_COMMAND) do
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Auto Minor Version Upgrade" )
    auto_minor_version_upgrade = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    auto_minor_version_upgrade.numVisible = 2
    auto_minor_version_upgrade.appendItem("true")	
    auto_minor_version_upgrade.appendItem("false")
    auto_minor_version_upgrade.setCurrentItem(0)
    auto_minor_version_upgrade.connect(SEL_COMMAND) do
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Use Latest Restorable Time" )
    use_latest_restorable_time = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    use_latest_restorable_time.numVisible = 2      
    use_latest_restorable_time.appendItem("true")	
    use_latest_restorable_time.appendItem("false")
    use_latest_restorable_time.setCurrentItem(1)
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "Restore Time" )
    restore_time = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    use_latest_restorable_time.connect(SEL_COMMAND) do
       if use_latest_restorable_time.itemCurrent?(0)
          restore_time.text = "" 
          restore_time.disable
       else
          restore_time.text = "2010-09-07T23:45:00Z" 
          restore_time.enable
       end
    end    
    if instance_id != nil and instance_id != ""
       source_db_instance_id.text = instance_id
    end   
    if params[:instance_class] != nil and params[:instance_class] != ""
       db_instance_class.text = params[:instance_class]
    end   
    if params[:endpoint_port] != nil and params[:endpoint_port] != "" 
       port.text =  params[:endpoint_port]
    end
    if params[:availability_zone] != nil and params[:availability_zone] != ""
       availability_zone.text = params[:availability_zone]
    end
    if params[:multi_az].to_s  == 'true'
       multi_az.setCurrentItem(0)
    end   
    if params[:auto_minor_version_upgrade].to_s  == 'false'
       auto_minor_version_upgrade.setCurrentItem(1)
    end
    restore_time.text = "2010-09-07T23:45:00Z" 
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Restore   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if source_db_instance_id.text == nil or source_db_instance_id.text == ""
         error_message("Error","Source DB Instance Id not specified")
       else
          if target_db_instance_id.text == nil or target_db_instance_id.text == ""
             error_message("Error","Target DB Instance id not specified")
          else
            if db_instance_class.text == nil or db_instance_class.text == ""
               error_message("Error","DB Instance Class not specified")
            else
      	       parms = {}
               parms[:use_latest_restorable_time] = true
               if use_latest_restorable_time.itemCurrent?(1)
                   parms[:use_latest_restorable_time] = false
                   parms[:restore_time] = restore_time.text
               end
               if port.text != nil or port.text != ""
                  parms[:endpoint_port] = port.text
               end
               if availability_zone.text != nil or availability_zone.text != ""
                  parms[:availability_zone] = availability_zone.text
               end
               parms[:instance_class] = db_instance_class.text
               if multi_az.itemCurrent?(0)
                  parms[:multi_az] = "true"
               end
               if auto_minor_version_upgrade.itemCurrent?(1)
                  parms[:auto_minor_version_upgrade] = "false"
               end
                restore_db_instance_to_point_in_time(source_db_instance_id.text, target_db_instance_id.text, parms)               
               if @created == true
                  self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
               end
            end   
          end
       end  
    end
  end 
  
  def restore_db_instance_to_point_in_time(source_db_instance_id, target_db_instance_id, params)
     rds = @ec2_main.environment.rds_connection
     if rds != nil
        begin
           r = rds.restore_db_instance_to_point_in_time(source_db_instance_id, target_db_instance_id, params)
           @target = r
           @created = true
        rescue
           error_message("Restore DBInstance Failed",$!.to_s)
        end 
     end
  end 

  def created
     @created
  end
  
  def target 
     @target
  end 
  
  def error_message(title,message)
     FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
