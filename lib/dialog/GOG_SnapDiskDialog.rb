require 'rubygems'
require 'fox16'
require 'fileutils'
require 'common/error_message'

include Fox

class GOG_SnapDiskDialog < FXDialogBox

  def initialize(owner, name)
    puts " GOG_SnapDialog.initialize"
    @saved = false
    @ec2_main = owner
    super(@ec2_main, "Create Snapshot", :opts => DECOR_ALL, :width => 500, :height => 150)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Disk Name" )
    disk_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
	disk_name.text = name
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Snapshot Name" )
    snap_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if disk_name.text == nil or disk_name.text == ""
         error_message("Error","Disk Name not specified")
	   elsif snap_name.text == nil or snap_name.text == ""
         error_message("Error","Snapshot Name not specified")	 
       else
         create_snap(disk_name.text, snap_name.text)
         if @saved == true
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end
       end
    end
  end 
  
  def create_snap(disk_name, snap_name)
      begin 
	   opts = {}   
	   opts['name'] = snap_name
       r = @ec2_main.environment.snapshots.insert_snapshot(disk_name, $google_zone, nil, opts )
       @saved = true
      rescue
        error_message("Create Snapshot Failed",$!)
      end 
  end 
  
  def saved
     @saved
  end

  def created
    @saved
  end

  def success
     @saved
  end
  
end
