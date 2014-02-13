require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class GOG_DiskAttachDialog < FXDialogBox

  def initialize(owner, curr_item)
    puts "GOG_DiskAttachDialog.initialize"
    @ec2_main = owner
    disk_volume = curr_item
    disk_server = ""
    @created = false
    super(owner, "Attach Disk     ", :opts => DECOR_ALL, :width => 400, :height => 200)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    
    FXLabel.new(frame1, "Disk" )
    volume = FXTextField.new(frame1, 20, nil, 0, :opts => TEXTFIELD_READONLY)
    volume.text = disk_volume
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Server     " )
    serverlist = FXComboBox.new(frame1, 35,
          	      :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    sa = @ec2_main.serverCache.instance_running_names
    i = 0
    while i<sa.length
       serverlist.appendItem(sa[i])
       disk_server = sa[i] if disk_server == ""
       i=i+1
    end
    serverlist.numVisible = 9
    serverlist.connect(SEL_COMMAND) do |sender, sel, data|
      disk_server = data
      sa = (disk_server).split"/" 
      disk_server = sa[0] if sa.size>1
    end
	FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Device     " )
    device = FXTextField.new(frame1, 25, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Attach   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
      attach_disk(disk_volume, disk_server, device.text)
      if @created == true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end
  end 
  
  def attach_disk(disk_volume, disk_server, disk_device)
      if disk_server["/"] != nil
         sa = (disk_server).split"/"
         disk_server = (sa[0]) if sa.size>1
       end
      begin
         disk_device = nil if disk_device == "" 	  
	     puts "*** disk_server #{disk_server} disk_volume #{disk_volume}"
         @ec2_main.environment.volumes.attach_disk(disk_server, $google_zone, disk_volume, disk_device)
         @created = true
      rescue
         error_message("Attach Disk Failed",$!)
      end
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
