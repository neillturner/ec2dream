
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'


include Fox

class EC2_SnapAttributeDialog < FXDialogBox

  def initialize(owner, snap_id)
        puts "SnapshotAttributeDialog.initialize"
        @ec2_main = owner
        if snap_id["/"] != nil
           sa = (snap_id).split"/"
           if sa.size>1
              snap_id = (sa[sa.size-1])
           end
        end        
        r = get_snap_volume_permissions(snap_id)
        super(owner, "Snapshot Attributes", :opts => DECOR_ALL, :width => 650, :height => 120)
	page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)        
        frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
 	FXLabel.new(frame1, "Snapshot Id" )
 	aws_id = FXTextField.new(frame1, 20, nil, 0, :opts => FRAME_SUNKEN|TEXT_READONLY)
 	aws_id.text = snap_id
	FXLabel.new(frame1, "" )
 	FXLabel.new(frame1, "Create Volume Groups" )
 	create_volume_groups = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXT_READONLY)
 	lp = r[:groups]
 	if lp != nil 
 	   lp.each do |p|
 	      if create_volume_groups.text == nil or create_volume_groups.text == ""
 	         create_volume_groups.text = p
 	      else   
 	         create_volume_groups = "#{create_volume_groups.text},#{p}"
 	      end
 	   end   
 	end
 	FXLabel.new(frame1, "(currently supports all)" )
 	FXLabel.new(frame1, "Create Volumes Users" )
 	create_volume_users = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXT_READONLY)
 	lp = r[:users]
 	if lp != nil 
 	   lp.each do |p|
 	      if create_volume_users.text == nil or create_volume_users.text == ""
 	         create_volume_users.text = p
 	      else   
 	         create_volume_users = "#{create_volume_users.text},#{p}"
 	      end
 	   end   
 	end
 	FXLabel.new(frame1, "" ) 	
        frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
        #FXLabel.new(frame1, "" )
        return_button = FXButton.new(frame2, "   &Return   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
        #FXLabel.new(frame1, "" )
        return_button.connect(SEL_COMMAND) do |sender, sel, data|
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
        end
  end 
  
  def get_snap_volume_permissions(snap_id)
        r = {}
        ec2 = @ec2_main.environment.connection
        if ec2 != nil
  	   begin
              r = ec2.describe_snapshot_attribute([snap_id])
           rescue
             puts "describe_snapshot_attribute #{$!.to_s}"
             # ignore auth failures 
             # error_message("Snapshot not found",$!.to_s)
           end
        else
      	   puts "***Error: No EC2 Connection"
        end  
        return r 
  end  
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
 
end