require 'rubygems'
require 'fox16'
require 'fileutils'
require 'common/error_message'

include Fox

class VAG_CreateDialog < FXDialogBox

  def initialize(owner)
    puts " VAG_CreateDialog.initialize"
    @saved = false
    @ec2_main = owner
    super(@ec2_main, "Create Vagrantfile", :opts => DECOR_ALL, :width => 350, :height => 110)
    frame1 = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Server" )
    server = FXTextField.new(frame1, 40, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_RIGHT)
    FXLabel.new(frame1, "" )
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
         create_vagrant_server(server.text)
         if @saved == true
           self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
         end
       end  
    end
  end 
  
  def create_vagrant_server(server)
      folder = "#{$ec2_main.settings.get('VAGRANT_REPOSITORY')}/#{server}"
      begin
        if File.exist?(folder)
           error_message("Error","Vagrant Server Already Defined")
           return        
        end
        rc = Dir.mkdir(folder, 0700)
        puts "*** rc #{rc}"
        @saved = true if rc == 0
        if @saved == false
           error_message("Error","Vagrant Server Directory create Failed")
        else
           s = "#{ENV['EC2DREAM_HOME']}/chef/Vagrantfile"
           d = "#{@ec2_main.settings.get('VAGRANT_REPOSITORY')}/#{server}"
           puts "*** Copy #{s} to #{d}"
           FileUtils.cp_r(s, d)        
        end   
      rescue
        error_message("Vagrant Server Directory create Failed",$!)
        return
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
