require 'rubygems'
require 'fox16'
require 'common/EC2_Properties'
require 'common/error_message'

include Fox

class LOC_CreateDialog < FXDialogBox

  def initialize(owner)
    puts " LOC_CreateDialog.initialize"
    @saved = false
    @ec2_main = owner
    super(@ec2_main, "Create Local Server", :opts => DECOR_ALL, :width => 450, :height => 250)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Server" )
    server = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Address" )
    address = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Chef Node" )
    chef_node = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "SSH User" )
    ssh_user = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "SSH Password" )
    ssh_password = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "SSH key" )
    ssh_key = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    ssh_key_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    ssh_key_button.icon = @magnifier
    ssh_key_button.tipText = "Browse..."
    ssh_key_button.connect(SEL_COMMAND) do
       dialog = FXFileDialog.new(frame1, "Select pem file")
       dialog.patternList = [
          "Pem Files (*.pem)"
       ]
       dialog.selectMode = SELECTFILE_EXISTING
       if dialog.execute != 0
          ssh_key.text = dialog.filename
       end
    end
    FXLabel.new(frame1, "Putty Key" )
    putty_key = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    putty_key_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    putty_key_button.icon = @magnifier
    putty_key_button.tipText = "Browse..."
    putty_key_button.connect(SEL_COMMAND) do
       dialog = FXFileDialog.new(frame1, "Select pem file")
       dialog.patternList = [
          "Pem Files (*.ppk)"
       ]
       dialog.selectMode = SELECTFILE_EXISTING
       if dialog.execute != 0
          putty_key.text = dialog.filename
       end
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Create   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
       if server.text == nil or server.text == ""
         error_message("Error","Server not specified")
       else
         create_local_server(server.text,address.text,chef_node.text,ssh_user.text,ssh_password.text,ssh_key.text,putty_key.text)
         if @saved == true
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end
       end  
    end
  end 
  
  def create_local_server(server,address,chef_node,ssh_user,ssh_password,ssh_key,putty_key)
     folder = "loc_server"
     loc = EC2_Properties.new
     if loc != nil
      begin
        if loc.exists(folder, server)
           error_message("Error","Local Server Already Exists")
           return        
        end
        properties = {}
        properties['server']=server
        properties['address']=address
        properties['chef_node']=chef_node
        properties['ssh_user']=ssh_user
        properties['ssh_password']=ssh_password
        properties['ssh_key']=ssh_key
        properties['putty_key']=putty_key 
        @saved = loc.save(folder, server, properties)
        if @saved == false
           error_message("Error","Create Local Server Failed")
        end   
      rescue
        error_message("Create Local Server",$!)
        return
      end
     end
  end 

  def saved
     @saved
  end

  def created
    @saved
  end

  def success
     @saved
  end
  
end
