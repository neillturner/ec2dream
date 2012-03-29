
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class RDS_InstanceDeleteDialog < FXDialogBox

  def initialize(owner, instance_id)
        puts "RDSInstanceDeleteDialog.initialize"
        @ec2_main = owner
        @deleted = false
        @skip = false
        super(owner, "Delete DB Instance - #{instance_id}", :opts => DECOR_ALL, :width => 450, :height => 120, :x => 300, :y => 200)
        @frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
 	FXLabel.new(@frame1, "" )
        skip_final_snapshot = FXCheckButton.new(@frame1,"Skip Final Snapshot", :opts => ICON_BEFORE_TEXT|LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X)
 	FXLabel.new(@frame1, "" )
	
        FXLabel.new(@frame1, "Final Snapshot Id" )
 	final_snapshot_id = FXTextField.new(@frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
 	today = DateTime.now
 	final_snapshot_id.text=instance_id.gsub("_","-")+ "-" + today.strftime("%Y%m%d")
        FXLabel.new(@frame1, "" )
        
        skip_final_snapshot.connect(SEL_COMMAND) do
          if @skip == false
             @skip = true
             final_snapshot_id.enabled = false
          else
             @skip = false
             final_snapshot_id.enabled = true
          end
        end         
        FXLabel.new(@frame1, "" )
        delete = FXButton.new(@frame1, "   &Delete   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
        FXLabel.new(@frame1, "" )
        delete.connect(SEL_COMMAND) do |sender, sel, data|
           if @skip == true 
              delete_rds_skip(instance_id)
           else
              if final_snapshot_id.text != nil and final_snapshot_id.text != ""
                 delete_rds(instance_id,final_snapshot_id.text)
              else
                 error_message("Error","No Final Snapshot Id specified")
              end
           end
           if @deleted == true
              self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
           end           
        end
  end 
  
  def delete_rds(instance,final_snapshot_id)
     rds = @ec2_main.environment.rds_connection
     if rds != nil
      	 params = {}
 	 params[:skip_final_snapshot] = false
      	 params[:snapshot_aws_id] = final_snapshot_id
         begin
            r = rds.delete_db_instance(instance,params)
            @deleted = true
         rescue
            error_message("Delete DB Instance Failed",$!.to_s)
         end        
     end
  end
  
  def delete_rds_skip(instance)
        rds = @ec2_main.environment.rds_connection
        if rds != nil
      	   params = {}
 	   params[:skip_final_snapshot] = true
           begin
              r = rds.delete_db_instance(instance,params)
              @deleted = true
           rescue
              error_message("Delete DB Instance Failed",$!.to_s)
           end      
        end
  end  
  
  def deleted
     @deleted
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
 
end