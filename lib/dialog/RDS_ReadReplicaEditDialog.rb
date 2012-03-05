
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'dialog/EC2_AvailZoneDialog'
require 'dialog/RDS_InstanceDialog'


include Fox

class RDS_ReadReplicaEditDialog < FXDialogBox

  def initialize(owner, r)
     	puts "RDS_ReadReplicaEditDialog .initialize"
     	@ec2_main = owner
     	@returned = false
     	@rr = r 
     	@title = "Create Read Replica"
    	if @rr[:db_instance_id] != nil and @rr[:db_instance_id] != ""
           @title = "Read Replica #{@rr[:db_instance_id]}" 
        end     	
     	@magnifier = @ec2_main.makeIcon("magnifier.png")
     	@magnifier.create
     	super(owner, @title, :opts => DECOR_ALL, :width => 500, :height => 200)
        page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)     	
     	frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
     	FXLabel.new(frame1, "Read Replica Instance Id" )
     	db_instance_id = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
     	FXLabel.new(frame1, "" )
     	FXLabel.new(frame1, "Source DB Instance Id" )
     	source_db_instance_id = FXTextField.new(frame1, 40, nil, 0, :opts => TEXTFIELD_INTEGER|LAYOUT_LEFT|TEXTFIELD_READONLY)
     	FXLabel.new(frame1, "" )
     	FXLabel.new(frame1, "DB Instance Class" )
     	db_instance_class  = FXTextField.new(frame1, 40, nil, 0, :opts => TEXTFIELD_INTEGER|LAYOUT_LEFT)
     	db_instance_class_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
     	db_instance_class_button.icon = @magnifier
     	db_instance_class_button.tipText = "Select DB Instance Class"
     	db_instance_class_button.connect(SEL_COMMAND) do
	   dialog = RDS_InstanceDialog.new(@ec2_main)
	   dialog.execute
	   type = dialog.selected
	   if type != nil and type != ""
	      db_instance_class.text=type
	   end   
	end
	FXLabel.new(frame1, "Port" )
	port = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
	FXLabel.new(frame1, "" )
        FXLabel.new(frame1, "Availability Zone")
 	availability_zone = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
 	availability_zone_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
	availability_zone_button.icon = @magnifier
	availability_zone_button.tipText = "Select Availability Zone"
	availability_zone_button.connect(SEL_COMMAND) do
	   @dialog = EC2_AvailZoneDialog.new(@ec2_main)
	   @dialog.execute
	   az = @dialog.selected
	   if az != nil and az != ""
	      availability_zone.text = az
	   end   
	end 	
    	FXLabel.new(frame1, "Auto Minor Version Upgrade" )
    	auto_minor_version_upgrade = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    	auto_minor_version_upgrade.numVisible = 2
    	auto_minor_version_upgrade.appendItem("true")	
    	auto_minor_version_upgrade.appendItem("false")
    	auto_minor_version_upgrade.setCurrentItem(1)
    	auto_minor_version_upgrade.connect(SEL_COMMAND) do
    	end    
    	FXLabel.new(frame1, "" )
    	source_db_instance_id.text = @rr[:source_db_instance_id]
    	if @rr[:db_instance_id] != nil and @rr[:db_instance_id] != ""
    	   db_instance_id.text = @rr[:db_instance_id]
    	   db_instance_class.text  = @rr[:instance_class]  
    	   port.text = @rr[:endpoint_port]  
    	   availability_zone.text  = @rr[:availability_zone] 
    	   if @rr[:auto_minor_version_upgrade].to_s == 'true'
    	      auto_minor_version_upgrade.setCurrentItem(0)
    	   end
    	   db_instance_id.enabled=false
    	   db_instance_class.enabled=false
    	   port.enabled=false
    	   availability_zone.enabled=false
    	   auto_minor_version_upgrade.enabled=false
        end 
        frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    	create = FXButton.new(frame2, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    	create.connect(SEL_COMMAND) do |sender, sel, data|
       	   if db_instance_id.text == nil or db_instance_id.text == ""
              error_message("Error","DB Instance Id not Specified")
           else
              @rr[:db_instance_id] = db_instance_id.text 
              @rr[:source_db_instance_id] = source_db_instance_id.text
       	      @rr[:instance_class] = db_instance_class.text
              @rr[:endpoint_port]   = port.text 
              @rr[:availability_zone] = availability_zone.text 
              if auto_minor_version_upgrade.itemCurrent?(0)
                 @rr[:auto_minor_version_upgrade] = "true"
              else
                 @rr[:auto_minor_version_upgrade] = "false"
              end
              @returned = true
              self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
           end
        end
  end 
  
  def read_replica
     @rr
  end 

  def returned
    @returned
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
