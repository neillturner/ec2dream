
require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class AS_BlockMappingEditDialog < FXDialogBox

  def initialize(owner,bmap)
    puts "AS_BlockMappingEditDialog.initialize"
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
       FXLabel.new(frame1, "Device Name" )
       device_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
       FXLabel.new(frame1, "" ) 
       FXLabel.new(frame1, "Virtual Name" )
       virtual_name = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
       FXLabel.new(frame1, "" )
       FXLabel.new(frame1, "Snapshot Id" )
       snap = FXTextField.new(frame1, 30, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
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

    FXLabel.new(frame1, "" )
    save = FXButton.new(frame1, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_LEFT)
    FXLabel.new(frame1, "" )
    save.connect(SEL_COMMAND) do |sender, sel, data|
       @bm[:device_name] = device_name.text
       @bm[:virtual_name] = virtual_name.text
       @bm[:ebs_snapshot_id] = nil
       @bm[:ebs_volume_size] = nil
       @bm[:ebs_delete_on_termination] = nil
       if snap.text != nil and snap.text != ""
          @bm[:ebs_snapshot_id] = snap.text
       end
       if  volume_size.text != nil and  volume_size.text != ""
          @bm[:ebs_volume_size] = volume_size.text
       end   
       if delete_on_termination.itemCurrent?(1) 
          @bm[:ebs_delete_on_termination] ="false"  
       else
          @bm[:ebs_delete_on_termination] ="true"
       end
       @saved = true
       self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    if @bm != nil
       device_name.text = @bm[:device_name]
       virtual_name.text = @bm[:virtual_name]
       snap.text = @bm[:ebs_snapshot_id]
       volume_size.text = @bm[:ebs_volume_size].to_s
       if @bm[:ebs_delete_on_termination] == "false"
          delete_on_termination.setCurrentItem(1)
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
  
  def success
     @saved
  end
  
  def block_mapping
     @bm
  end   
  
end
