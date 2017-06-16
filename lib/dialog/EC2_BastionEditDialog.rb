require 'rubygems'
require 'fox16'
require 'common/error_message'

include Fox

class EC2_BastionEditDialog < FXDialogBox

  def initialize(owner, parm)
    #puts "BastionEditDialog.initialize"
    @saved = false
    @ec2_main = owner
    @parm = {}
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create
    super(@ec2_main, "Configure Bastion Host", :opts => DECOR_ALL, :width => 450, :height => 260)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Bastion Host" )
    bastion_host = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Bastion Port" )
    bastion_port = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Bastion User" )
    bastion_user = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Bastion Password" )
    bastion_password = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Bastion SSH key" )
    bastion_ssh_key = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    bastion_ssh_key_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    bastion_ssh_key_button.icon = @magnifier
    bastion_ssh_key_button.tipText = "Browse..."
    bastion_ssh_key_button.connect(SEL_COMMAND) do
      dialog = FXFileDialog.new(frame1, "Select pem file")
      dialog.patternList = [
        "Pem Files (*.pem)"
      ]
      dialog.selectMode = SELECTFILE_EXISTING
      if dialog.execute != 0
        bastion_ssh_key.text = dialog.filename
      end
    end
    FXLabel.new(frame1, "Bastion Putty Key" )
    bastion_putty_key = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    bastion_putty_key_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    bastion_putty_key_button.icon = @magnifier
    bastion_putty_key_button.tipText = "Browse..."
    bastion_putty_key_button.connect(SEL_COMMAND) do
      dialog = FXFileDialog.new(frame1, "Select pem file")
      dialog.patternList = [
        "Pem Files (*.ppk)"
      ]
      dialog.selectMode = SELECTFILE_EXISTING
      if dialog.execute != 0
        bastion_putty_key.text = dialog.filename
      end
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    create = FXButton.new(frame1, "   &Save   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    create.connect(SEL_COMMAND) do |sender, sel, data|
      @parm['bastion_host']=bastion_host.text
      @parm['bastion_port']=bastion_port.text
      @parm['bastion_user']=bastion_user.text
      @parm['bastion_password']=bastion_password.text
      @parm['bastion_ssh_key']=bastion_ssh_key.text
      @parm['bastion_putty_key']=bastion_putty_key.text
      @saved = true
      self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
    end
    bastion_host.text = parm['bastion_host'] if parm['bastion_host'] != nil
    bastion_port.text = parm['bastion_port'] if parm['bastion_port'] != nil
    bastion_user.text = parm['bastion_user'] if parm['bastion_user'] != nil
    bastion_password.text = parm['bastion_password'] if parm['bastion_password'] != nil
    bastion_ssh_key.text = parm['bastion_ssh_key'] if parm['bastion_ssh_key'] != nil
    bastion_putty_key.text = parm['bastion_putty_key'] if parm['bastion_putty_key'] != nil
  end
  def saved
    @saved
  end

  def success
    @saved
  end
  def selected
    @parm
  end
end
