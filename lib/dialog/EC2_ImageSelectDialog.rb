require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_ImageSelectDialog < FXDialogBox

  def initialize(owner,search_type="Owned By Me",search_platform="All Platforms",search_root="ebs",search_search="")
    puts "ImageSelectDialog.initialize"
    @ec2_main = owner
    @curr_img = ""
    @image_search = search_search
    @image_type = search_type
    @image_platform = search_platform
    @image_root = search_root
    @selected = false
    @viewing =  @ec2_main.environment.images.viewing
    @platform =  @ec2_main.environment.images.platform
    @device =  @ec2_main.environment.images.device
    super(owner, "Select Image", :opts => DECOR_ALL, :width => 700, :height => 75)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "Viewing:" )
    type = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    type.numVisible = 10
    @viewing.each do |e|
      type.appendItem(e)
    end
    type.connect(SEL_COMMAND) do |sender, sel, data|
      @image_type = data
    end
    i = @viewing.index(search_type)
    if i != nil
      type.setCurrentItem(i)
    end
    platform = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    platform.numVisible = 3
    @platform.each do |e|
      platform.appendItem(e)
    end
    platform.connect(SEL_COMMAND) do |sender, sel, data|
      @image_platform = data
    end
    i = @platform.index(search_platform)
    if i != nil
      platform.setCurrentItem(i)
    end
    root_device = FXComboBox.new(frame1, 15, :opts => COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
    root_device.numVisible = 2
    @device.each do |e|
      root_device.appendItem(e)
    end
    root_device.connect(SEL_COMMAND) do |sender, sel, data|
      @image_root = data
    end
    i = @device.index(search_platform)
    if i != nil
      root_device.setCurrentItem(i)
    end
    @search = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    if search_search != ""
      @search.text = search_search
    end
    frame1a = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    search_button = FXButton.new(frame1a, "   &Select   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    search_button.connect(SEL_COMMAND) do |sender, sel, data|
      @selected = true
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
  end
  def search
    @search.text
  end
  def type
    @image_type
  end
  def platform
    @image_platform
  end
  def root_device_type
    @image_root
  end
  def selected
    @selected
  end
end
