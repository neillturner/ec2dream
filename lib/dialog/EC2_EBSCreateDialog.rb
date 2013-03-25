
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/EC2_ResourceTags'
require 'dialog/EC2_TagsEditDialog'
require 'dialog/EC2_AvailZoneDialog'
require 'dialog/EC2_SnapDialog'
require 'common/error_message'

include Fox

class EC2_EBSCreateDialog < FXDialogBox

  def initialize(owner, snap_id=nil, snap_size=nil)
    puts "EBSCreateDialog.initialize"
    @ec2_main = owner
    ebs_size = snap_size.to_s
    ebs_type = "Standard"
    ebs_capacity = "GiB"
    ebs_zone = ""
    ebs_snap = snap_id.to_s
    ebs_name = ""
    ebs_description = ""
    @created = false
    resource_tags = nil
    @edit = @ec2_main.makeIcon("application_edit.png")
    @edit.create
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create    
    super(owner, "Create Block Storage Volume", :opts => DECOR_ALL, :width => 500, :height => 225)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    if  !@ec2_main.settings.openstack
       FXLabel.new(frame1, "Tags" )
       tags = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
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
       FXLabel.new(frame1, "Name" )
       name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
       name.text = ebs_name 
       name.connect(SEL_COMMAND) do |sender, sel, data|
         ebs_name = data
       end
       FXLabel.new(frame1, "" )
       FXLabel.new(frame1, "Description" )
       description = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_LEFT)
       description.text = ebs_description 
       description.connect(SEL_COMMAND) do |sender, sel, data|
         ebs_description = data
       end
       FXLabel.new(frame1, "" )
    end
    FXLabel.new(frame1, "Volume Type" )
    volume_type = FXComboBox.new(frame1, 20,
  	      :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_RIGHT)
    if  @ec2_main.settings.openstack_rackspace	      
       volume_type.numVisible = 2
       volume_type.appendItem("SATA");
       volume_type.appendItem("SSD");
       ebs_type = "SATA"
    else
       volume_type.numVisible = 1
       volume_type.appendItem("Standard");    
    end
    volume_type.connect(SEL_COMMAND) do |sender, sel, data|
       ebs_type = data
    end	
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Size" )
    size = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_INTEGER|LAYOUT_RIGHT)
    size.text = ebs_size
    capacity = FXComboBox.new(frame1, 5,
  	      :opts => COMBOBOX_STATIC|COMBOBOX_NO_REPLACE|LAYOUT_RIGHT)
    if  !@ec2_main.settings.openstack	      
       capacity.numVisible = 2
       capacity.appendItem("GiB");
       capacity.appendItem("TiB");
    else
       capacity.numVisible = 1
       capacity.appendItem("GiB");
    end   
    capacity.connect(SEL_COMMAND) do |sender, sel, data|
       ebs_capacity = data
    end	
    FXLabel.new(frame1, "Availability Zone" )
    zone = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    zone_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    zone_button.icon = @magnifier
    zone_button.tipText = "Select..."
    zone_button.connect(SEL_COMMAND) do
       dialog = EC2_AvailZoneDialog.new(@ec2_main)
       dialog.execute
       it = dialog.selected
       if it != nil and it != ""
          zone.text = it
          ebs_zone = it
       end	    
    end            
    FXLabel.new(frame1, "Snapshot" )
    snap = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    snap.text = ebs_snap 
    snap.connect(SEL_COMMAND) do |sender, sel, data|
      ebs_snap = data
    end	
    snap_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    snap_button.icon = @magnifier
    snap_button.tipText = "Select..."
    snap_button.connect(SEL_COMMAND) do
       dialog = EC2_SnapDialog.new(@ec2_main)
       dialog.execute
       it = dialog.selected
       if it != nil and it != ""
          snap.text = it
          ebs_snap = it
       end	    
    end               
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
            create_ebs(ebs_snap, ebs_size, ebs_zone, resource_tags, ebs_name, ebs_description, ebs_type)
            if @created == true
              self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
            end
         end  
       end  
    end
  end 
  
  def create_ebs(snap, size, zone, tags, name, description, type)
      begin 
       r = @ec2_main.environment.volumes.create_volume(zone, size, snap, name, description, type)
       @created = true
       vol = r[:aws_id] 
      rescue
        error_message("Create Volume Failed",$!)
      end
      if @created 
         begin 
           if tags != nil and tags != ""
              tags.assign(vol)
           end   
         rescue
           error_message("Create Tags Failed",$!)
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
