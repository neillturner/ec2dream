
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'dialog/EC2_EBSAttachDeviceDialog'
require 'common/error_message'

include Fox

class EC2_EBSAttachDialog < FXDialogBox

  def initialize(owner, curr_item)
    puts "EBSAttachDialog.initialize"
    
    @ec2_main = owner
    ebs_volume = curr_item
    ebs_device = "/dev/sdf"
    ebs_server = ""
    @created = false
    super(owner, "Attach Volume     ", :opts => DECOR_ALL, :width => 400, :height => 120)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    
    FXLabel.new(frame1, "Volume" )
    volume = FXTextField.new(frame1, 20, nil, 0, :opts => TEXTFIELD_READONLY)
    volume.text = ebs_volume
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Server     " )
    serverlist = FXComboBox.new(frame1, 35,
          	      :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    sa = @ec2_main.serverCache.instance_running_names
    i = 0
    while i<sa.length
       serverlist.appendItem(sa[i])
       if ebs_server == ""
            ebs_server = sa[i]
       end   
       i=i+1
    end
    serverlist.numVisible = 9
    serverlist.connect(SEL_COMMAND) do |sender, sel, data|
      ebs_server = data
      sa = (ebs_server).split"/" 
      if sa.size>1
         ebs_server = sa[1]
      end   
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Device     " )
    device = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    device.text=ebs_device
    device_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    device_button.icon = @magnifier
    device_button.tipText = "Select Device"
    device_button.connect(SEL_COMMAND) do
	@dialog = EC2_EBSAttachDeviceDialog.new(@ec2_main)
	@dialog.execute
	if @dialog.selected != nil and @dialog.selected != ""
	   ebs_device = @dialog.selected
	   device.text = ebs_device
	end   
    end    
    #FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Attach   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
      attach_ebs(ebs_volume, ebs_server, device.text)
      if @created == true
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end
    end
  end 
  
  def attach_ebs(ebs_volume, ebs_server, ebs_device)
      sa = (ebs_volume).split" "
      ebs_volume = (sa[0])
      if ebs_volume["/"] != nil
         sa = (ebs_volume).split"/"
         if sa.size>1
            ebs_volume = (sa[1])
         end
      end      
      if ebs_server["/"] != nil
         sa = (ebs_server).split"/"
         if sa.size>1
            ebs_server = (sa[1])
         end
      end
      if ebs_device.include? "windows"
        ebs_device = ebs_device[-4..-1]
      end  
         begin 
            @ec2_main.environment.volumes.attach_volume(ebs_server, ebs_volume, ebs_device)
            @created = true
         rescue
            error_message("Attach Volume Failed",$!)
         end
  end    
  
  def pad(i)
      if i < 10
        p = "0#{i}"
      else
        p = "#{i}"
      end
      return p
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
