require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class EC2_ImageSelectDialog < FXDialogBox

  def initialize(owner)
    puts "ImageSelectDialog.initialize"
    @ec2_main = owner
    @curr_img = ""
    @image_search = ""
    @image_type = "Owned By Me"
    @image_platform = "All Platforms"
    @image_root ="instance-store"
    @selected = false
    @ec2 = @ec2_main.environment.connection
    if @ec2 != nil
       super(owner, "Select Image", :opts => DECOR_ALL, :width => 700, :height => 75)
       page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
       frame1 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
       FXLabel.new(frame1, "Viewing:" )
       type = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
       type.numVisible = 10
       type.appendItem("Owned By Me");
       type.appendItem("Amazon Images");
       type.appendItem("Public Images");
       type.appendItem("Private Images");
       type.appendItem("alestic");
       type.appendItem("bitnami");
       type.appendItem("Canonical");
       type.appendItem("Elastic-Server");
       type.appendItem("JumpBox");
       type.appendItem("RBuilder");
       type.appendItem("rightscale");
       type.appendItem("windows");
       
       type.connect(SEL_COMMAND) do |sender, sel, data|
          @image_type = data
       end
       platform = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
       platform.numVisible = 3
       platform.appendItem("All Architectures");
       platform.appendItem("Small(i386)");
       platform.appendItem("Large(x86_64)");
       platform.connect(SEL_COMMAND) do |sender, sel, data|
          @image_platform = data
       end
       root_device = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
       root_device.numVisible = 2
       root_device.appendItem("instance-store");
       root_device.appendItem("ebs");
       root_device.connect(SEL_COMMAND) do |sender, sel, data|
          @image_root = data
       end       
       @search = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
       frame1a = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
       search_button = FXButton.new(frame1a, "   &Select   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
       search_button.connect(SEL_COMMAND) do |sender, sel, data|
          @selected = true 
          self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
       end  
    end
  end
  
  def search
    return @search.text
  end  
  
  def type
     return @image_type
  end 
  
  def platform
     return @image_platform
  end 
  
  def root_device_type
       return @image_root
  end
  
  def selected
     @selected
  end  
    
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
