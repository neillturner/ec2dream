
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_SnapRegisterDialog < FXDialogBox

  def initialize(owner,snap)
    @ec2_main = owner
    snap_id = snap
    snap_nickname = ""
    sa = (snap_id).split"/"
    if sa.size>1
       snap_id = sa[1]
       snap_nickname = sa[0]
    end    
    @created = false
    @image_platform = "i386"
    options = {}
    super(owner, "Register Image", :opts => DECOR_ALL, :width => 400, :height => 250)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Snapshot Id" )
    snapshot_id = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_READONLY)
    snapshot_id.text = snap_id
    FXLabel.new(frame1, "Description" )
    description = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "Architecture" )
    platform = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    platform.numVisible = 2
    platform.appendItem("i386");
    platform.appendItem("x86_64");
    platform.connect(SEL_COMMAND) do |sender, sel, data|
       @image_platform = data
    end
    FXLabel.new(frame1, "Image Name" )
    image_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    today = DateTime.now
    image_name.text = "xxxxxxx-"+ today.strftime("%y%m%d")
    FXLabel.new(frame1, "Device Name" )
    device_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    device_name.text = "/dev/sda1"
    FXLabel.new(frame1, "Kernel Id" )
    kernel_id = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "Ramdisk Id" )        
    ramdisk_id = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "Delete EBS on Termination" )
    delete_on_termination = FXComboBox.new(frame1, 15, :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    delete_on_termination.numVisible = 2      
    delete_on_termination.appendItem("true")	
    delete_on_termination.appendItem("false")
    delete_on_termination.setCurrentItem(0)    
    #frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    FXLabel.new(frame1,"")
    create = FXButton.new(frame1, "   &Register   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
       ec2 = @ec2_main.environment.connection
       if ec2 != nil
         r = {}
         if kernel_id.text == nil or kernel_id.text == ""
            error_message("Error","Kernel Id not specified") 
         else
	  begin
	     options[:name] = image_name.text
	     options[:root_device_name] = device_name.text
	     if description.text != nil
	        options[:description] = description.text
             end
             options[:architecture] = @image_platform
             if kernel_id.text != nil
                options[:kernel_id] = kernel_id.text
             end 
             if ramdisk_id.text != nil
                options[:ramdisk_id] = ramdisk_id.text
             end             
             bm = {}
             bm[:ebs_snapshot_id] = snapshot_id.text
             bm[:device_name] = device_name.text
             if delete_on_termination.itemCurrent?(1)
                bm[:ebs_delete_on_termination] = false
             else
                bm[:ebs_delete_on_termination] = true
             end             
             options[:block_device_mappings] =bm  
             r = ec2.register_image(options)
          rescue
             error_message("Register Image failed",$!.to_s)
          end             
          @created = true
         end 
       end
    end
    exit_button = FXButton.new(frame1, "   &Exit   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    exit_button.connect(SEL_COMMAND) do |sender, sel, data|
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end    
     
  
  def created
     @created
  end
  
  def error_message(title,message)
    FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
end