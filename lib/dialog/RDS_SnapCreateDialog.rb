
require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class RDS_SnapCreateDialog < FXDialogBox

  def initialize(owner)
    puts "RDSSnapCreateDialog.initialize"
    @ec2_main = owner
    sel_instance = ""
    @created = false
    super(owner, "Create DB Snapshot", :opts => DECOR_ALL, :width => 400, :height => 100)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    
    FXLabel.new(frame1, "DB Instance Id" )
    instance = FXComboBox.new(frame1, 38,:opts => COMBOBOX_NO_REPLACE|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
     
    FXLabel.new(frame1, "DB Snapshot id" )
    db_snapshot_id = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    db_instances = @ec2_main.serverCache.db_instances
    db_instances.each do |key, r|
        s = r[:aws_id]
        instance.appendItem(s)
        if db_snapshot_id.text == nil or db_snapshot_id.text == ""
           today = DateTime.now
           sel_instance = s
           db_snapshot_id.text=s.gsub("_","-")+ "-" + today.strftime("%y%m%d")
        end   
    end
    instance.numVisible = 4
    
    instance.connect(SEL_COMMAND) do |sender, sel, data|
      sel_instance = data
      today = DateTime.now
      db_snapshot_id.text=sel_instance.gsub("_","-")+ "-" + today.strftime("%y%m%d")
    end
    
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if db_snapshot_id.text == nil or db_snapshot_id.text == ""
         error_message("Error","DB Snapshot not specified")
       else
         if sel_instance == nil or sel_instance == ""
             error_message("Error","DB Instance not selected")
         else    
            create_db_snapshot(db_snapshot_id.text, sel_instance)
            if @created == true
              self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
            end  
         end
       end  
    end
  end 
  
  def create_db_snapshot(db_snapshot_id, db_instance_id)
     rds = @ec2_main.environment.rds_connection
     if rds != nil
      begin 
       r = rds.create_db_snapshot(db_snapshot_id, db_instance_id)
       @created = true
      rescue
        error_message("Create DB Snapshots Failed",$!.to_s)
      end 
     end
  end 
  

  def created
    @created
  end
  
  def error_message(title,message)
      FXMessageBox.warning(@ec2_main,MBOX_OK,title,message)
  end
  
end
