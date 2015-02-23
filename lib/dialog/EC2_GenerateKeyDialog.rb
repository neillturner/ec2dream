require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'

include Fox

class EC2_GenerateKeyDialog < FXDialogBox

  def initialize(owner,title,item)
    puts "EC2_GenerateKeyDialog.initialize"
    @ec2_main = owner
    @title = title
    @saved = false
    @magnifier = @ec2_main.makeIcon("magnifier.png")
    @magnifier.create    
    @link = @ec2_main.makeIcon("link_break.png")
    @link.create    
    super(owner, @title, :opts => DECOR_ALL, :width => 550, :height => 90)
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)    
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, @title )
    value = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    value_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    value_button.icon = @magnifier
    value_button.tipText = "Browse..."
    value_button.connect(SEL_COMMAND) do
	   dialog = FXFileDialog.new(frame1, "Select pem file")
	   dialog.patternList = [
	          "Pem Files (*.pem)"
	   ]
	   dialog.selectMode = SELECTFILE_EXISTING
	   if dialog.execute != 0
	      value.text = dialog.filename
	   end
	end
    FXLabel.new(frame1, "" )
    frame2 = FXHorizontalFrame.new(page1, 3, :opts => MATRIX_BY_COLUMNS||LAYOUT_FILL)  
    putty_generate_button = FXButton.new(frame2, " PuTTYgen Key Generator ", :opts => BUTTON_NORMAL|LAYOUT_LEFT|LAYOUT_CENTER_X)
    putty_generate_button.icon = @link
    putty_generate_button.tipText = " PuTTYgen Key Generator "
    putty_generate_button.connect(SEL_COMMAND) do    
      puts "settings.PuttyGenerateButton.connect"
      if value.text != nil and value.text != ''
         system("cmd.exe /C "+ENV['EC2DREAM_HOME']+"/putty//puttygen "+"\""+value.text+"\""+"  -t rsa")
      else
         error_message("Error","No SSH_PRIVATE_KEY  specified")
      end
    end
    FXLabel.new(frame2, "In PuTTYgen press OK and then press SAVE PRIVATE KEY" )
    if item != nil
        value.text = item
    end
  end
 
end
