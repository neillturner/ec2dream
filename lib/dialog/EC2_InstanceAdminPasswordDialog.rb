require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_InstanceAdminPasswordDialog < FXDialogBox

  def initialize(owner, instance_id)
    puts "InstanceAdminPasswordDialog.initialize"
    @ec2_main = owner
    @created = false
    @password = ""
    super(owner, "Change Admin Password on Server "+instance_id, :opts => DECOR_ALL, :width => 550, :height => 100)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )    
    FXLabel.new(frame1, "New Admin Password" )
    admin_password = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|TEXTFIELD_PASSWD)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Change   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if admin_password.text != nil and admin_password.text != ""
          begin
             @password = admin_password.text
             r = @ec2_main.environment.servers.change_password_server(instance_id, @password)
             @created = true
          rescue
             error_message("Admin Password Change Failed",$!)
          end 
          if @created == true
             self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
          end
       else
          error_message("Error","New Admin Password Not Specified")
       end
    end 
  end
 
  def saved
     @created
  end
  
  def updated
     @created
  end
  
  def success
     @created
  end
  
  def selected
     @password
  end 

end


