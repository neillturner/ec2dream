
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'dialog/EC2_ImageDialog'
require 'dialog/EC2_SnapDialog'
require 'common/error_message'

include Fox

class GOG_DiskCreateDialog < FXDialogBox

  def initialize(owner)
    puts "GOG_DiskCreateDialog.initialize"
    @ec2_main = owner
    @disk_name = ""
    @created = false
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create    
    super(owner, "Create Disk", :opts => DECOR_ALL, :width => 600, :height => 300)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Name" )
    name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Description" )
    description = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Zone" )
    zone = FXTextField.new(frame1, 40, nil, 0, :opts => LAYOUT_LEFT|TEXTFIELD_READONLY)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Image Name" )
    image_name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    image_name_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    image_name_button.icon = @magnifier
    image_name_button.tipText = "Select Image"
    image_name_button.connect(SEL_COMMAND) do
      dialog = EC2_ImageDialog.new(@ec2_main,"Owned By Me","All Platforms","all")
      dialog.execute
      img = dialog.selected
      img_name = dialog.name
      if img != nil and img != ""
        image_name.text = img_name
      end   
    end
    FXLabel.new(frame1, "Size (GB)" )
    size = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Snapshot" )
    snap = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    snap_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    snap_button.icon = @magnifier
    snap_button.tipText = "Select..."
    snap_button.connect(SEL_COMMAND) do
      dialog = EC2_SnapDialog.new(@ec2_main)
      dialog.execute
      item = dialog.selected
      if item != nil and item != ""
        snap.text = item
      end	    
    end  
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
      @created = false
      if name.text == nil or name.text == ""
        error_message("Error","Disk name not specified") 
      else
        @disk_name = name.text
        create_disk(name.text, zone.text, image_name.text, size.text, snap.text, description.text)
        if @created == true
          self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
        end
      end  
    end
    name.text = ""
    description.text = ""
    zone.text = $google_zone
    size.text = "10"
    image_name.text = ""
    snap.text = ""	 
  end 
  def create_disk(disk_name, zone_name, image_name, size, snap_name, description)
    begin 
      opts = {}
      disk_size = size.to_f
      opts['sizeGb'] = disk_size if disk_size != nil and disk_size > 0
      opts['sourceSnapshot'] = snap_name if snap_name != nil and snap_name != ""
      opts['description'] = description if description != nil and description != ""
      image_name = nil if image_name == ""
      r = @ec2_main.environment.volumes.insert_disk(disk_name, zone_name, image_name, opts)
      @created = true
    rescue
      error_message("Insert Disk Failed",$!)
    end
  end 
  def name
    @disk_name
  end
  def saved
    @created
  end
  def created
    @created
  end
  def success
    @created
  end

end
