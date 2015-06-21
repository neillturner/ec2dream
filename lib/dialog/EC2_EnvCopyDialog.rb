require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'fileutils'

include Fox

class EC2_EnvCopyDialog < FXDialogBox

  def initialize(owner)
    puts "EnvCopyDialog.initialize"
    @ec2_main = owner
    @env = ""
    @copied = false
    envs = Dir.entries(@ec2_main.settings.get_system('REPOSITORY_LOCATION'))
    super(owner, "Copy Environment", :opts => DECOR_ALL, :width => 500, :height => 125)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Source Environment" )
    @source_env = FXComboBox.new(frame1, 40,
    :opts => COMBOBOX_NO_REPLACE|LAYOUT_FILL_X)
    @source_env.numVisible = 6
    @source_env.appendItem("")
    envs.each do |e|
      if e != "." and e != ".."
        @source_env.appendItem(e)
      end 
    end
    @source_env.connect(SEL_COMMAND) do |sender, sel, data|
      @env = sender.text
    end
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "Destination Environment" )
    @dest_env = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    FXLabel.new(frame1, "" )
    copy = FXButton.new(frame1, "   &Copy   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )
    copy.connect(SEL_COMMAND) do |sender, sel, data|
      copy_env(@env,@dest_env.text)
      if @copied == true
        @ec2_main.settings.put_system('ENVIRONMENT',@dest_env.text)
        @ec2_main.settings.save_system
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end  
    end
  end 
  def copy_env(source,dest)
    puts "EnvCopyDialog.copy_env "+source
    if source == nil or source == ""
      FXMessageBox.warning(self,MBOX_OK,"Error","Source Environment Not Specified")
    else
      if dest == nil or dest == ""
        FXMessageBox.warning(self,MBOX_OK,"Error","Destination Environment Not Specified")
      else
        s = @ec2_main.settings.get_system('REPOSITORY_LOCATION')+"/"+source
        d = @ec2_main.settings.get_system('REPOSITORY_LOCATION')+"/"+dest
        if File.exists?(d)
          FXMessageBox.warning(self,MBOX_OK,"Error","Destination Environment already exists") 
        else
          FileUtils.cp_r(s, d)
          @copied = true
          @ec2_main.imageCache.set_status("empty")
        end
      end 
    end
  end
  def saved
    @copied
  end
  def copied 
    @copied
  end  

  def success
    @copied
  end  
end
