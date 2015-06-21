require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class GOG_DiskDetachDialog < FXDialogBox

  def initialize(owner, curr_item)
    puts "GOG_DiskDetachDialog.initialize"
    @ec2_main = owner
    disk_volume = curr_item
    disk_server = ""
    @created = false
    super(owner, "Detach Disk     ", :opts => DECOR_ALL, :width => 400, :height => 120)
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
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Detach   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
      sa = (disk_server).split"/" 
      disk_server = sa[0] if sa.size>1
      puts "*** disk_server #{disk_server}"
      begin 
        r = @ec2_main.environment.servers.get_server(disk_server,$google_zone)
      rescue 
      end	  
      device_name = ""
      if r != nil
        r['disks'].each do |a|
          if disk_volume = google_last(a['source'])
            device_name = a['deviceName']
          end 			  
        end
        if device_name != nil and device_name !=""
          detach_disk(disk_server, device_name)
        else	  
          error_message("Disk device name not found on instance","Disk not found on instance #{disk_server}")	  
        end		
      else 
        error_message("Server not found","Server instance #{disk_server} not found")
      end
      if @created == true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end
  end 
  def detach_disk(disk_server, device_name)
    if disk_server["/"] != nil
      sa = (disk_server).split"/"
      disk_server = (sa[0]) if sa.size>1
    end
    begin 
      puts "** detach_disk  #{disk_server} device_name #{device_name}"
      @ec2_main.environment.volumes.detach_disk(disk_server, $google_zone, device_name)
      @created = true
    rescue
      error_message("Detach Disk Failed",$!)
    end
  end    
  def google_last(parm)
    if parm == nil or parm == "" or parm.index('/') == nil
      return parm
    else  
      return parm.split("/").last
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
