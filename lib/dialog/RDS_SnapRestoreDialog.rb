
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class RDS_SnapRestoreDialog < FXDialogBox

  def initialize(owner, snap_id, instance_id, params)
    puts "RDSSnapRestoreDialog.initialize"
    @ec2_main = owner
    @created = false
    super(owner, "Restore DB Instance from DB Snapshot", :opts => DECOR_ALL, :width => 350, :height => 225)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)  
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "DB Snapshot id" )
    db_snapshot_id = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "DB Instance id" )
    db_instance_id = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "DB Instance Class" )
    db_instance_class = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Port" )
    port = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Availability  Zone" )
    availability_zone = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
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
    db_snapshot_id.text = snap_id
    db_instance_id.text = instance_id
    if params[:instance_class] != nil and params[:instance_class] != ""
       db_instance_class.text = params[:instance_class]
    end   
    if params[:endpoint_port] != nil and params[:endpoint_port] != "" 
       port.text =  params[:endpoint_port]
    end
    if params[:availability_zone] != nil and params[:availability_zone] != ""
       availability_zone.text = params[:availability_zone]
    end
    #if params[:multi_az]  == 'true'
    #   multi_az.setCurrentItem(0)
    #end   
    #if params[:auto_minor_version_upgrade']  == 'false'
    #   auto_minor_version_upgrade.setCurrentItem(1)
    #end
  
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Restore   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if db_snapshot_id.text == nil or db_snapshot_id.text == ""
         error_message("Error","DB Snapshot id not specified")
       else
          if db_instance_id.text == nil or db_instance_id.text == ""
             error_message("Error","DB Instance id not specified")
          else
            if db_instance_class.text == nil or db_instance_class.text == ""
               error_message("Error","DB Instance Class not specified")
            else
      	       parms = {}
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
               restore_db_instance(db_snapshot_id, db_instance_id, parms)
               if @created == true
                  self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
               end
            end   
          end
       end  
    end
  end 
  
  def restore_db_instance(source_db_instance_id, target_db_instance_id, params)
     rds = @ec2_main.environment.rds_connection
     if rds != nil

      begin 
         r = rds.restore_db_instance_from_db_snapshot(source_db_instance_id, target_db_instance_id, params)
         @created = true
      rescue
         error_message("Restore DBInstance Failed",$!.to_s)
      end 
     end
  end 
  

  def created
    @created
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
