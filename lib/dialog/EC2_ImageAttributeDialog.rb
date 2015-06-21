
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'
require 'common/browser'

include Fox

class EC2_ImageAttributeDialog < FXDialogBox

  def initialize(owner, image)
    puts "ImageAttributeDialog.initialize"
    @ec2_main = owner
    image_id = image
    super(owner, "Image Attributes", :opts => DECOR_ALL, :width => 600, :height => 550)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Image Id" )
    aws_id = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
    aws_id.text = image_id
    aws_id_button = FXButton.new(frame1, " ",:opts => BUTTON_TOOLBAR|LAYOUT_LEFT)
    aws_id_icon = @ec2_main.makeIcon("cloudmarket.png")
    aws_id_icon.create
    aws_id_button.icon = aws_id_icon
    aws_id_button.tipText = "  CloudMarket Info  "
    aws_id_button.connect(SEL_COMMAND) do |sender, sel, data|
      browser("http://thecloudmarket.com/image/#{aws_id.text}")
    end
    FXLabel.new(frame1, "Location" )
    aws_location = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Name" )
    ami_name = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Description" )
    description = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Owner" )
    frame1a = FXHorizontalFrame.new(frame1, LAYOUT_FILL, :padding => 0)
    aws_owner = FXTextField.new(frame1a, 21, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1a, "Image Owner Alias" )
    image_owner_alias = FXTextField.new(frame1a, 21, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Visibility" )
    visibility = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)

    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Tags" )
    tags = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Architecture" )
    aws_architecture = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Image Type" )
    aws_image_type = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Kernel Id" )
    frame1c = FXHorizontalFrame.new(frame1, LAYOUT_FILL, :padding => 0)
    aws_kernel_id = FXTextField.new(frame1c, 24, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1c, "RamDisk Id" )
    aws_ramdisk_id = FXTextField.new(frame1c, 24, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "State" )
    aws_state = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Product Codes" )
    aws_product_codes = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)

    #FXLabel.new(frame1, "" )
    #FXLabel.new(frame1, "launch Permission Groups" )
    #launch_permission_groups = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)

    #FXLabel.new(frame1, "" )
    #FXLabel.new(frame1, "launch Permission Users" )
    #launch_permission_users = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)

    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Platform" )
    platform = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "State Reason" )
    code = FXTextField.new(frame1, 60, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Root Device Type" )
    frame1e = FXHorizontalFrame.new(frame1, LAYOUT_FILL, :padding => 0)
    root_device_type = FXTextField.new(frame1e, 21, nil, 0, :opts => TEXT_READONLY)
        FXLabel.new(frame1e, "Root Device Name" )
    root_device_name = FXTextField.new(frame1e, 21, nil, 0, :opts => TEXT_READONLY)

    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Block Devices")
    block_devices = FXText.new(frame1, :height => 60, :opts => LAYOUT_FIX_HEIGHT|TEXT_WORDWRAP|LAYOUT_FILL|TEXT_READONLY, :padding => 0)

    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    return_button = FXButton.new(frame2, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X|BUTTON_INITIAL)
    return_button.connect(SEL_COMMAND) do |sender, sel, data|
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    r = get_image(image_id)
    #a = get_image_launch_permissions(image_id)
    a = nil
    if r != nil
      #if r.instance_of?(Hash)
      description.text = r['description']
      aws_owner.text = r['imageOwnerId']
      aws_location.text = r['imageLocation']
      ami_name.text = r['imageId']
      image_owner_alias.text = r['imageOwnerAlias']
      if r['isPublic'] == true
        visibility.text = "Public"
      else
        visibility.text = "Private"
      end
      aws_architecture.text = r['architecture']
      aws_image_type.text = r['imageType']
      aws_kernel_id.text = r['kernelId']
      aws_ramdisk_id.text = r['ramdiskId']
      aws_state.text = r['imageState']
      aws_product_codes.text = r['productCodes'].to_s if r['productCodes'] != []
      platform.text = r['platform']
      code.text = r['stateReason'].to_s if r['stateReason'] != {}
      tags.text = r['tagSet'].to_s if r['tagSet'] != {}
      root_device_type.text = r['rootDeviceType']
      root_device_name.text = r['rootDeviceName']
      if r['blockDeviceMapping'] != nil
        r['blockDeviceMapping'].each do |m|
          if block_devices.text==""
            block_devices.text=m.to_s
          else
            block_devices.text=block_devices.text+m.to_s
          end
        end
      end
      #else
      # ami_name.text =  r.name
      # l = {}
      # begin
      #    l = r.links[0]
      # rescue
      # end
      # #puts "** #{l[0]}"
      # #a=l[0]
      # aws_location.text = "#{l["href"]}"
      # description.text = "Created #{r.created_at} Updated #{r.updated_at}"
      # aws_state.text = r.status
      # code.text = "Progress #{r.progress}%"
      # platform.text =  "#{r.server}"
      #end
    end
    if a != nil
      lp = a[:groups]
      if lp != nil
        lp.each do |p|
          if launch_permission_groups.text == nil or launch_permission_groups.text == ""
            launch_permission_groups.text = p
          else
            launch_permission_groups = "#{launch_permission_groups.text},#{p}"
          end
        end
      end
      lp = a[:users]
      if lp != nil
        lp.each do |p|
          if launch_permission_users.text == nil or launch_permission_users.text == ""
            launch_permission_users.text = p
          else
            launch_permission_users = "#{launch_permission_users.text},#{p}"
          end
        end
      end
    end
  end
  def get_image(image_id)
    r = {}
    begin
      r = @ec2_main.environment.images.get(image_id)
      puts "image in json #{r.to_json}"
    rescue
      puts "Image #{image_id} not found"
      r = nil
    end
    r
  end
  def success
    @false
  end
end