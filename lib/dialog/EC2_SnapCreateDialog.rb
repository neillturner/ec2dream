
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'common/EC2_ResourceTags'
require 'dialog/EC2_TagsEditDialog'
include Fox

class EC2_SnapCreateDialog < FXDialogBox

  def initialize(owner,ebs)
    @ec2_main = owner
    snap_ebs = ebs
    resource_tags = nil
    sa = (snap_ebs).split"/"
    if sa.size>1
       snap_ebs = sa[1]
       today = DateTime.now
       d = today.strftime("%y%m%d")
       resource_tags=EC2_ResourceTags.new(@ec2_main,nil,"#{sa[0]}-#{d}")
    end
    @created = false
    super(owner, "Create Snapshot", :opts => DECOR_ALL, :width => 500, :height => 120)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "EBS Volume" )
    ebs_volume = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT|TEXTFIELD_READONLY)
    ebs_volume.text = snap_ebs
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Tags" )
    tags = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
    @edit = @ec2_main.makeIcon("application_edit.png")
    @edit.create
    tags_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    tags_button.icon = @edit
    tags_button.tipText = "Edit Tags"
    tags_button.connect(SEL_COMMAND) do
       dialog = EC2_TagsEditDialog.new(@ec2_main, "EBS Volume", resource_tags)
       dialog.execute
       if dialog.saved
	  resource_tags = dialog.resource_tags
	  tags.text = resource_tags.show
       end   
    end
    FXLabel.new(frame1, "Description" )
    description = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    create = FXButton.new(frame2, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    create.connect(SEL_COMMAND) do |sender, sel, data|
       ec2 = @ec2_main.environment.connection
       if ec2 != nil
          r = {}
          snap_id = ""
	  begin 
             r = ec2.create_snapshot(snap_ebs,description.text)
             snap_id = r[:aws_id]
          rescue
             error_message("EBS Create Snapshot failed",$!.to_s)
             return
          end             
          @created = true
          begin 
             if tags.text != nil and tags.text != ""
                resource_tags.assign(snap_id)
             end   
          rescue
             error_message("Create Tags Failed",$!.to_s)
             return
        end
       end
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    if resource_tags != nil
	 tags.text = resource_tags.show 
    end 
  end    
  
  def created
     @created
  end
  
  def error_message(title,message)
    FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
