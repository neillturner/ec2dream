
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'
require 'dialog/EC2_EBSAttachDeviceDialog'
require 'dialog/EC2_SnapDialog'

include Fox

class EC2_BlockMappingEditDialog < FXDialogBox

  def initialize(owner,bmap,image_bm=false)
    puts "BlockMappingEditDialog.initialize"
    @ec2_main = owner
    @title = ""
    if bmap == nil 
       @bm = {}
       @title = "Add Block Device"
    else
       @bm = bmap
       @title = "Edit Block Device"
    end
    @saved = false
    super(owner, @title, :opts => DECOR_ALL, :width => 400, :height => 175)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    if image_bm
       FXLabel.new(frame1, "Device Name" )
       device_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
       device_name.enabled = false
       FXLabel.new(frame1, "" ) 
       FXLabel.new(frame1, "Virtual Name" )
       virtual_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
       virtual_name.enabled = false
       FXLabel.new(frame1, "" )
       FXLabel.new(frame1, "Snapshot Id" )
       snap = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT|TEXTFIELD_READONLY)
       snap.enabled = false
       FXLabel.new(frame1, "" )    
       FXLabel.new(frame1, "Volume Size (GB)" )
       volume_size = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_INTEGER|LAYOUT_RIGHT)
       FXLabel.new(frame1, "" )
       FXLabel.new(frame1, "Delete on Termination" )
       delete_on_termination = FXComboBox.new(frame1, 15, :opts => LAYOUT_RIGHT)
       delete_on_termination.numVisible = 2
       if @bm != nil
         delete_on_termination.appendItem("true")
         delete_on_termination.appendItem("false")
         if @bm[:ebs_delete_on_termination] == "true"
           delete_on_termination.setCurrentItem(0)  
         else  
           delete_on_termination.setCurrentItem(1)
         end  
         
       end
       # delete_on_termination.enabled = false
       FXLabel.new(frame1, "" )    
    else
       FXLabel.new(frame1, "Device Name" )
       device_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
       device_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
       @magnifier = @ec2_main.makeIcon("magnifier.png")
       @magnifier.create
       device_button.icon = @magnifier
       device_button.tipText = "Select Device"
       device_button.connect(SEL_COMMAND) do
   	  dialog = EC2_EBSAttachDeviceDialog.new(@ec2_main)
	  dialog.execute
	  if dialog.selected != nil and dialog.selected != ""
	     device_name.text = dialog.selected
	     if device_name.text.index("windows ") == 0 
	        device_name.text = device_name.text.sub("windows ","")
	     end   
	  end   
       end 
       FXLabel.new(frame1, "Virtual Name" )
       virtual_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
       FXLabel.new(frame1, "" )
       FXLabel.new(frame1, "Snapshot Id" )
       snap = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
       snap_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
       snap_button.icon = @magnifier
       snap_button.tipText = "Select Snapshot"
       snap_button.connect(SEL_COMMAND) do
	  dialog = EC2_SnapDialog.new(@ec2_main)
	  dialog.execute
	  if dialog.selected != nil and dialog.selected != ""
	     snap.text = dialog.selected
	  end   
       end    
       FXLabel.new(frame1, "Volume Size (GB)" )
       volume_size = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_INTEGER|LAYOUT_RIGHT)
       FXLabel.new(frame1, "" )
       FXLabel.new(frame1, "Delete on Termination" )
       delete_on_termination = FXComboBox.new(frame1, 15, :opts => LAYOUT_RIGHT)
       delete_on_termination.numVisible = 2      
       delete_on_termination.appendItem("true")	
       delete_on_termination.appendItem("false")
       delete_on_termination.setCurrentItem(0)
       FXLabel.new(frame1, "" )
    end
    FXLabel.new(frame1, "" )
    save = FXButton.new(frame1, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
       @bm[:device_name] = device_name.text
       @bm[:virtual_name] = virtual_name.text
       if snap.text != nil and snap.text != ""
          @bm[:ebs_snapshot_id] = snap.text
          @bm[:ebs_volume_size] = volume_size.text
          #if image_bm == false
             if delete_on_termination.itemCurrent?(1) 
                @bm[:ebs_delete_on_termination] ="false"  
             else
                @bm[:ebs_delete_on_termination] ="true"
             end   
          #end
       end   
       @saved = true
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    if @bm != nil
       device_name.text = @bm[:device_name]
       virtual_name.text = @bm[:virtual_name]
       snap.text = @bm[:ebs_snapshot_id]
       volume_size.text = @bm[:ebs_volume_size].to_s
       if image_bm == false
          if @bm[:ebs_delete_on_termination] == "false"
             delete_on_termination.setCurrentItem(1)
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
  
  def saved
    @saved
  end
  
  def block_mapping
     @bm
  end   
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
