require 'rubygems'
require 'fox16'
require 'net/http'
require 'resolv'
require 'common/error_message'

include Fox

class EC2_SystemDialog < FXDialogBox

  def initialize(owner)
    puts "SystemDialog.initialize"
    @ec2_main = owner
    @valid_loc = false
    @settings = @ec2_main.settings
    super(owner, "Environment Repository", :opts => DECOR_ALL, :width => 600, :height => 250, :x => 300, :y => 200 )
    page1 = FXVerticalFrame.new(self, LAYOUT_FILL, :padding => 0)
    frame1a = FXMatrix.new(page1, 1, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1a, "The Environment Repository is where configuration is stored." )
    FXLabel.new(frame1a, "NOTE: You must first create the directory using Windows Explorer or the command line" )
    frame1 = FXMatrix.new(page1, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL)
    FXLabel.new(frame1, "Repository Location" )
    location = FXTextField.new(frame1, 60, nil, 0, :opts => FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    location_button = FXButton.new(frame1, "", :opts => BUTTON_TOOLBAR)
    magnifier = @ec2_main.makeIcon("magnifier.png")
    magnifier.create
    location_button.icon = magnifier
    location_button.tipText = "Browse..."
    location_button.connect(SEL_COMMAND) do
      if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
        location.text = FXDirDialog.getOpenDirectory(frame1, "Select Repository Location", "C:/")
      else
        location.text = FXDirDialog.getOpenDirectory(frame1, "Select Repository Location", "/")
      end 
    end
    FXLabel.new(frame1, "" )
    ok = FXButton.new(frame1, "   &OK   ", nil, self, ID_ACCEPT, FRAME_RAISED|LAYOUT_LEFT|LAYOUT_CENTER_X)
    FXLabel.new(frame1, "" )

    ok.connect(SEL_COMMAND) do |sender, sel, data|
      @valid_loc = true
      envs = nil
      begin
        envs = Dir.entries(location.text)
      rescue
        @valid_loc = false
        error_message("Repository Location does not exist",$!)
      end
      if @valid_loc == true
        @settings.put_system("REPOSITORY_LOCATION",location.text)
        @settings.put_system("REPOSITORY_REMOTE",location.text)
        defaults
        @settings.put_system('ENVIRONMENT','')
        @settings.put_system('AUTO','false') 
        @settings.save_system()
        self.handle(sender, MKUINT(ID_ACCEPT, SEL_COMMAND), nil)
      end      
    end
  end
  def selected
    return @valid_loc
  end 

  def defaults
    if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
      @settings.put_system('EXTERNAL_EDITOR',"notepad")  # default to notepad
      @settings.put_system('EXTERNAL_BROWSER',"C:\\Program Files\\Internet Explorer\\iexplore.exe")  
    else
      if RUBY_PLATFORM.index("linux") != nil
        @settings.put_system('EXTERNAL_EDITOR',"gedit")  # default to vi
        @settings.put_system('EXTERNAL_BROWSER',"/usr/bin/firefox")
      else
        @settings.put_system('EXTERNAL_EDITOR',"xterm -e /Applications/TextEdit.app/Contents/MacOS/TextEdit")  
        @settings.put_system('EXTERNAL_BROWSER',"open")
      end   
    end
    @settings.put_system('TIMEZONE',"UTC")
  end

end
