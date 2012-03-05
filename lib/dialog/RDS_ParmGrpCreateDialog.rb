require 'rubygems'
require 'fox16'
require 'right_aws'
require 'net/http'
require 'resolv'

include Fox

class RDS_ParmGrpCreateDialog < FXDialogBox

  def initialize(owner)
    puts "RDSParmGrpCreateDialog.initialize"
    @ec2_main = owner
    @created = false
    super(owner, "Create DB Parameter Group", :opts => DECOR_ALL, :width => 400, :height => 120)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "DB Parameter Group Name" )
    name = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Description" )
    description = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Family" )
    family = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN)
    FXLabel.new(frame1, "" )
    family.text = "mysql5.1"
    frame2 = FXHorizontalFrame.new(page1,LAYOUT_FILL, :padding => 0)
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame2, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if name.text == nil or name.text == ""
         error_message("Error","DB Parameter Group Name not specified")
       else
         create_db_parm_grp(name.text,description.text,family.text)
         if @created == true
            self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end         
       end  
    end
  end 
  
  def create_db_parm_grp(name,description,family)
     rds = @ec2_main.environment.rds_connection
     if rds != nil
        begin 
           r = rds.create_db_parameter_group(name, description, family)
           @created = true
        rescue
           error_message("Create DB Parameter Group Failed",$!.to_s)
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
