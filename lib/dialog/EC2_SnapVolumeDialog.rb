
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/EC2_ResourceTags'
require 'dialog/EC2_TagsEditDialog'
require 'common/error_message'

include Fox

class EC2_SnapVolumeDialog < FXDialogBox

  def initialize(owner,ebs,ebs_name="")
    @ec2_main = owner
    snap_ebs = ebs
    snap_name = ebs_name
    snap_force = false
    resource_tags = nil
    sa = (snap_ebs).split"/"
    if sa.size>1
      snap_ebs = sa[1]
      today = DateTime.now
      d = today.strftime("%Y%m%d")
      resource_tags=EC2_ResourceTags.new(@ec2_main,nil,"#{sa[0]}-#{d}")
    end
    @edit = @ec2_main.makeIcon("application_edit.png")
    @edit.create
    @created = false
    super(owner, "Create Snapshot", :opts => DECOR_ALL, :width => 500, :height => 210)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    ebs_volume_label = FXLabel.new(frame1, "Volume" )
    ebs_volume_label.tipText = "Volume to create snaphot from" 
    ebs_volume = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_READONLY)
    ebs_volume.text = snap_ebs
    FXLabel.new(frame1, "" )
    if  !@ec2_main.settings.openstack
      tags_label = FXLabel.new(frame1, "Tags" )
      tags_label.tipText = "Tags to identify the disk volume. Keyword and Value pairs.\nTag keys and values are case sensitive.\nFOR AWS: Don't use the aws: prefix in your tag names or values"
      tags = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_READONLY)
      tags_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
      tags_button.icon = @edit
      tags_button.tipText = "Edit Tags"
      tags_button.connect(SEL_COMMAND) do
        dialog = EC2_TagsEditDialog.new(@ec2_main, "Volume", resource_tags)
        dialog.execute
        if dialog.saved
          resource_tags = dialog.resource_tags
          tags.text = resource_tags.show
        end
      end   
    end
    if  @ec2_main.settings.openstack
      name_label = FXLabel.new(frame1, "Name" )
      name_label.tipText = "The Name of the Disk Snapshot" 
      name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
      name.text = snap_name 
      name.connect(SEL_COMMAND) do |sender, sel, data|
        snap_name = data
      end
      FXLabel.new(frame1, "" )
    end   
    description_label = FXLabel.new(frame1, "Description" )
    description_label.tipText = "Description of the Disk Snapshot" 
    description = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    if  @ec2_main.settings.openstack
      force_label = FXLabel.new(frame1, "Force" )
      force_label.tipText = "Force the snapshot creation" 
      force = FXComboBox.new(frame1, 10,
      :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_LEFT)
      force.numVisible = 2
      force.appendItem("false");
      force.appendItem("true");
      force.connect(SEL_COMMAND) do |sender, sel, data|
        if data == "true"
          snap_force = true
        else
          snap_force = false
        end   
      end	
    end    
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
      r = {}
      snap_id = ""
      @created = false
      desc = description.text
      if desc == nil or desc == ""
        today = DateTime.now
        d = today.strftime("%Y%m%d")
        desc = "snapshot of #{snap_ebs} taken #{d}" 
      end   
      begin 
        r = @ec2_main.environment.snapshots.create_volume_snapshot(snap_ebs, snap_name, desc, snap_force)
        snap_id = r[:aws_id]
        @created = true
      rescue
        error_message("Create Snapshot failed",$!)
      end             
      if @created
        begin 
          if tags != nil and tags.text != nil and tags.text != ""
            resource_tags.assign(snap_id)
          end   
        rescue
          error_message("Create Tags Failed",$!)
        end   
      end
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    if resource_tags != nil and tags != nil 
      tags.text = resource_tags.show 
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
