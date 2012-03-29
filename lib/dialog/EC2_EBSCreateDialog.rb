
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'common/EC2_ResourceTags'
require 'dialog/EC2_TagsEditDialog'


include Fox

class EC2_EBSCreateDialog < FXDialogBox

  def initialize(owner, snap_id=nil, snap_size=nil)
    puts "EBSCreateDialog.initialize"
    @ec2_main = owner
    ebs_size = snap_size.to_s
    ebs_capacity = "GiB"
    ebs_zone = ""
    ebs_snap = snap_id.to_s
    @created = false
    resource_tags = nil
    super(owner, "Create EBS Volume", :opts => DECOR_ALL, :width => 600, :height => 150)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Tags" )
    tags = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
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
    FXLabel.new(frame1, "Size" )
    size = FXTextField.new(frame1, 20, nil, 0, :opts => TEXTFIELD_INTEGER|LAYOUT_RIGHT)
    size.text = ebs_size
    capacity = FXComboBox.new(frame1, 5,
  	      :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_RIGHT)
    capacity.numVisible = 2
    capacity.appendItem("GiB");
    capacity.appendItem("TiB");
    capacity.connect(SEL_COMMAND) do |sender, sel, data|
       ebs_capacity = data
    end	
    FXLabel.new(frame1, "Availability Zone" )
    zone = FXComboBox.new(frame1, 20,
      	      :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_RIGHT)
    ec2 = @ec2_main.environment.connection
    if ec2 != nil
      ec2.describe_availability_zones.each do |r|
        if ebs_zone == ""
          ebs_zone = r[:zone_name]
        end
        zone.appendItem(r[:zone_name])
      end
      zone.numVisible = 3
    end
    zone.connect(SEL_COMMAND) do |sender, sel, data|
       ebs_zone = data
    end	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Snapshot" )
    snap = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    snap.text = ebs_snap 
    snap.connect(SEL_COMMAND) do |sender, sel, data|
      ebs_snap = data
    end	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
       @created = false
       size_error = false
       if size.text == nil or size.text == ""
         error_message("Error","Size not specified")
       else
         begin
            ebs_size = Integer(size.text)
         rescue 
             error_message("Error","Size invalid")
             size_error = true 
         end
         if !size_error
            if ebs_capacity == "TiB"
              ebs_size = ebs_size * 1000
            end
            sa = (ebs_snap).split("/") 
            if sa.size>1
	       ebs_snap = sa[1].rstrip
  	    end
            create_ebs(ebs_snap, ebs_size, ebs_zone, resource_tags)
            if @created == true
              self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
            end
         end  
       end  
    end
  end 
  
  def create_ebs(snap, size, zone, tags)
     ec2 = @ec2_main.environment.connection
     if ec2 != nil
      begin 
       r = ec2.create_volume(snap, size, zone)
       @created = true
       vol = r[:aws_id] 
      rescue
        error_message("Create Volume Failed",$!.to_s)
      end
      if @created 
         begin 
           if tags != nil and tags != ""
              tags.assign(vol)
           end   
         rescue
           error_message("Create Tags Failed",$!.to_s)
         end
      end
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
  
  def created
    @created
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
